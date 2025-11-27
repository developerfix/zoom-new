import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'helpers/html_stub.dart' as html if (dart.library.html) 'dart:html';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'node/constants/node_types.dart';
import 'node/gestures/two_finger_zoom_handler.dart';
import 'node/models/draggable_card.dart';
import 'node/models/connection.dart';
import 'node/models/global_settings.dart';
import 'node/painting/infinite_dot_grid.dart';
import 'node/widgets/add_event_dialog.dart';
import 'node/widgets/draggable_card_widget.dart';
import 'node/widgets/canvas_sidebar.dart';
import 'node/widgets/canvas_bottom_toolbar.dart';
import 'node/widgets/frosted_glass_overlay.dart';
import 'node/widgets/right_panel.dart';
import 'node/widgets/top_bar.dart';
import 'node/widgets/connection_painter.dart';

class _CanvasState {
  final List<DraggableCard> cards;
  final List<Connection> connections;
  final double scale;
  final Offset offset;

  _CanvasState({
    required this.cards,
    required this.connections,
    required this.scale,
    required this.offset,
  });

  // Deep copy helper
  _CanvasState copy() {
    return _CanvasState(
      cards: List<DraggableCard>.from(cards.map((c) => c.copy())),
      connections: List<Connection>.from(connections.map((c) => c.copy())),
      scale: scale,
      offset: offset,
    );
  }
}
class AgentAutomationScreen extends StatefulWidget {
  const AgentAutomationScreen({super.key, required String agentName});

  @override
  State<AgentAutomationScreen> createState() => _AgentAutomationScreenState();
}

class _AgentAutomationScreenState extends State<AgentAutomationScreen> {
  double _currentScale = 1.0;
  Offset _offset = Offset.zero;
  int? _hoveredCardIndex; // tracks which card is hovered
  Set<int> _connectedCardIndices = {}; // cards connected to the hovered one
  // Scale gesture state
  Offset _startFocalPoint = Offset.zero;
  Offset _startOffset = Offset.zero;
  double _startScale = 1.0;
  bool _isRightPanelVisible = true;
  bool _isMagicBuilderActive = false;
// Undo/Redo history
  final List<_CanvasState> _history = [];
  final List<_CanvasState> _redoStack = [];
  bool _isCanvasLocked = false;
  DraggableCard? _selectedCard;
// Optional: prevent history bloat during rapid changes (e.g., dragging)
  Timer? _historyDebounceTimer;

  // Two-finger zoom handler
  late TwoFingerZoomHandler _twoFingerZoomHandler;

  // Canvas key for coordinate conversion
  final GlobalKey _canvasKey = GlobalKey();

  final _rightPanelKey = GlobalKey<RightPanelState>();


  // Draggable cards
  List<DraggableCard> _cards = [
    DraggableCard(
      position: Offset(100, 100),
      title: 'Card 1',
      // color: Colors.blue[200]!,
      zIndex: 0,
    ),
    DraggableCard(
      position: Offset(300, 200),
      title: 'Card 2',
      // color: Colors.green[200]!,
      zIndex: 1,
    ),
    DraggableCard(
      position: Offset(500, 400),
      title: 'Card 3',
      // color: Colors.purple[200]!,
      zIndex: 2,
    ),
  ];

  // Currently dragged card index
  int? _draggedCardIndex;

  // Connection state
  List<Connection> _connections = [];
  int? _dragFromCardIndex;
  PortSide? _dragFromPortSide;
  int? _dragFromSetVarIndex;
  Offset? _dragStartPosition;
  Offset? _dragCurrentPosition;
  String? _hoveredConnectionId;
  Set<String> _connectedPorts = {};
  Map<String, dynamic>? _nearestTargetPort;

  // Store actual port GlobalKeys: "cardIndex_setVarIndex" -> GlobalKey
  final Map<String, GlobalKey> _portKeys = {};

  // Get or create a GlobalKey for a port
  GlobalKey _getPortKey(int cardIndex, int setVarIndex) {
    final key = '${cardIndex}_$setVarIndex';
    return _portKeys.putIfAbsent(key, () => GlobalKey());
  }

  // Get actual port position from GlobalKey
  Offset? _getActualPortPosition(int cardIndex, int setVarIndex) {
    final key = '${cardIndex}_$setVarIndex';
    final globalKey = _portKeys[key];
    if (globalKey == null) return null;

    final RenderBox? box = globalKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      final globalPos = box.localToGlobal(Offset(box.size.width / 2, box.size.height / 2));
      return _globalToLocal(globalPos);
    }
    return null;
  }

  // Build map of all actual port positions for ConnectionPainter
  Map<String, Offset> _buildActualPortPositions() {
    final Map<String, Offset> positions = {};
    for (final entry in _portKeys.entries) {
      final globalKey = entry.value;
      final RenderBox? box = globalKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        final globalPos = box.localToGlobal(Offset(box.size.width / 2, box.size.height / 2));
        positions[entry.key] = _globalToLocal(globalPos);
      }
    }
    return positions;
  }

  // Constants
  static const double minScale = 0.1;
  static const double maxScale = 5.0;
  static const double zoomStep = 0.2;

  GlobalSettings _globalSettings = GlobalSettings();

  @override
  void dispose() {
    _historyDebounceTimer?.cancel();
    super.dispose();
  }
  void _deleteCard(int cardIndex) {
    setState(() {
      // 1. Remove all connections involving this card
      _connections.removeWhere((conn) =>
      conn.fromCardIndex == cardIndex || conn.toCardIndex == cardIndex);

      // 2. Remove the card
      _cards.removeAt(cardIndex);

      // 3. Re-index remaining cards' connections
      for (int i = 0; i < _connections.length; i++) {
        final conn = _connections[i];
        _connections[i] = Connection(
          id: conn.id,
          fromCardIndex: conn.fromCardIndex > cardIndex ? conn.fromCardIndex - 1 : conn.fromCardIndex,
          toCardIndex: conn.toCardIndex > cardIndex ? conn.toCardIndex - 1 : conn.toCardIndex,
          fromSide: conn.fromSide,
          toSide: conn.toSide,
          fromPortIndex: conn.fromPortIndex,
          toPortIndex: conn.toPortIndex,
        );
      }

      // 4. Rebuild connected ports
      _updateConnectedPorts();
    });
    _saveToHistory(); // 👈 Save to undo stack
  }
  String _generateCopyTitle(String originalTitle) {
    final copyPattern = RegExp(r' \(copy(?: (\d+))?\)$');
    final match = copyPattern.firstMatch(originalTitle);

    if (match == null) {
      return '$originalTitle (copy)';
    } else {
      final numberStr = match.group(1);
      if (numberStr == null) {
        // "Title (copy)" → "Title (copy 2)"
        return originalTitle.replaceFirst(copyPattern, ' (copy 2)');
      } else {
        final nextNumber = int.parse(numberStr) + 1;
        return originalTitle.replaceFirst(copyPattern, ' (copy $nextNumber)');
      }
    }
  }  void _duplicateCard(int cardIndex) {
    final originalCard = _cards[cardIndex];

    // ✅ Use advanced naming
    String newTitle = _generateCopyTitle(originalCard.title);

    final duplicatedCard = DraggableCard(
      position: Offset(
        originalCard.position.dx + 30,
        originalCard.position.dy + 30,
      ),
      title: newTitle, // 👈 updated
      iconKey: originalCard.iconKey,
      textContent: originalCard.textContent,
      isCollapsed: originalCard.isCollapsed,
      zIndex: _cards.length,
    );

    // Deep-copy SetVariables
    duplicatedCard.setSetVariables(
        List<SetVariable>.from(originalCard.setVariables.map((sv) =>
            SetVariable(name: sv.name, value: sv.value)
        ))
    );

    setState(() {
      _cards.add(duplicatedCard);
    });
    _saveToHistory();
  }

  void _toggleMagicBuilder() {
    setState(() {
      _isMagicBuilderActive = !_isMagicBuilderActive;
    });
  }

  void _toggleRightPanel() {
    setState(() {
      _isRightPanelVisible = !_isRightPanelVisible;
    });
  }
  void _exportCanvas() async {
    final exportData = {
      'agent_id': '',
      'channel': 'voice',
      'last_modification_timestamp': DateTime.now().millisecondsSinceEpoch,
      'agent_name': 'Canvas Export',
      'response_engine': {
        'type': 'conversation-flow',
        'version': 0,
        'conversation_flow_id': 'conversation_flow_${DateTime.now().millisecondsSinceEpoch}',
      },
      'language': _globalSettings.language, // 👈 use global setting
      // 'language': 'en-US',
      'opt_out_sensitive_data_storage': false,
      'global_settings': _globalSettings.toJson(), // 👈 ADD THIS

      'data_storage_setting': 'everything',
      'canvas_data': {
        'cards': _cards.map((card) => card.toJson()).toList(),
        'connections': _connections.map((conn) => conn.toJson()).toList(),
        'canvas_scale': _currentScale,
        'canvas_offset': {'dx': _offset.dx, 'dy': _offset.dy},
      },
      'post_call_analysis_data': [], // Add your analysis data here if needed
    };

    // Convert to JSON string
    final jsonString = _jsonEncode(exportData);

    // Save to file or copy to clipboard
    await _saveToFile(jsonString);
  }
  void _importCanvas(String jsonString) {
    try {
      final Map<String, dynamic> data = _jsonDecode(jsonString);
      // 👇 LOAD GLOBAL SETTINGS
      if (data['global_settings'] != null) {
        _globalSettings = GlobalSettings.fromJson(data['global_settings']);
      }

      if (data['canvas_data'] != null) {
        final canvasData = data['canvas_data'];

        // Load cards
        final List<DraggableCard> importedCards = [];
        if (canvasData['cards'] != null) {
          for (var cardJson in canvasData['cards']) {
            importedCards.add(DraggableCard.fromJson(cardJson));
          }
        }

        // Load connections
        final List<Connection> importedConnections = [];
        if (canvasData['connections'] != null) {
          for (var connJson in canvasData['connections']) {
            importedConnections.add(Connection.fromJson(connJson));
          }
        }

        // Load canvas state
        final double scale = (canvasData['canvas_scale'] as num?)?.toDouble() ?? 1.0;

        // Fix: Properly handle the offset map
        final offsetData = canvasData['canvas_offset'] as Map<String, dynamic>? ?? {};
        final Offset offset = Offset(
          (offsetData['dx'] as num?)?.toDouble() ?? 0.0,
          (offsetData['dy'] as num?)?.toDouble() ?? 0.0,
        );

        // Update state
        setState(() {
          _cards = importedCards;
          _connections = importedConnections;
          _currentScale = scale;
          _offset = offset;
          // Update connected ports set
          _updateConnectedPorts();
        });
      }
    } catch (e) {
      print('Error importing canvas: $e');
      // Show error message to user
    }
  }

// Helper methods for JSON encoding/decoding
  String _jsonEncode(dynamic data) {
    return JsonEncoder.withIndent('  ').convert(data);
  }

  dynamic _jsonDecode(String jsonString) {
    return json.decode(jsonString);
  }

// Replace your _saveToFile and _loadFromFile methods with these simpler versions:

  Future<void> _saveToFile(String content) async {
    if (kIsWeb) {
      // For web, create a data URL and trigger download
      final blob = html.Blob([content]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = 'canvas_export.json';
      html.document.body!.children.add(anchor);
      anchor.click();
      html.document.body!.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Canvas exported successfully')),
      );
    } else {
      // Mobile/Desktop: Use path_provider
      try {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/canvas_export.json');
        await file.writeAsString(content);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Canvas exported to: ${file.path}')),
        );
      } catch (e) {
        print('Error saving file: $e');
      }
    }
  }
  Future<String> _loadFromFile() async {
    if (kIsWeb) {
      // Create file input element for web
      final input = html.FileUploadInputElement();
      input.accept = '.json';

      Completer<String> completer = Completer<String>();

      input.onChange.listen((event) {
        final files = input.files;
        if (files != null && files.isNotEmpty) {
          final file = files.first;
          final reader = html.FileReader();

          reader.onLoadEnd.listen((event) {
            completer.complete(reader.result as String);
          });

          reader.readAsText(file);
        } else {
          completer.complete('');
        }
      });

      input.click();
      return completer.future;
    } else {
      // Mobile/Desktop: Use path_provider
      try {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/canvas_export.json');
        final content = await file.readAsString();
        return content;
      } catch (e) {
        print('Error loading file: $e');
        return '';
      }
    }
  }

  Future<void> _downloadFile(String content, String fileName) async {
    // For web, you can use js interop or a different approach
    // This is a simplified version - you might need to implement proper web file download
    print('Web download would happen here: $fileName');

    // For now, let's just show the JSON in a dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Exported JSON'),
          content: Container(
            width: 500,
            height: 300,
            child: SingleChildScrollView(
              child: SelectableText(content),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<String> _pickFile() async {
    // For web, implement file picker
    print('Web file picker would happen here');
    return '';
  }
  void _saveToHistory() {
    // Clear redo stack on new action
    _redoStack.clear();

    // Debounce rapid saves (e.g., during drag)
    _historyDebounceTimer?.cancel();
    _historyDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return; // 👈 ADD THIS
      final state = _CanvasState(
        cards: List<DraggableCard>.from(_cards.map((c) => c.copy())),
        connections: List<Connection>.from(_connections.map((c) => c.copy())),
        scale: _currentScale,
        offset: _offset,
      );
      _history.add(state);
      if (_history.length > 50) _history.removeAt(0);
    });
  }

  void _undo() {
    if (_history.isEmpty) return;

    final state = _history.removeLast();
    _redoStack.add(_getCurrentState()); // Save current for redo

    _restoreState(state);
  }

  void _redo() {
    if (_redoStack.isEmpty) return;

    final state = _redoStack.removeLast();
    _history.add(_getCurrentState()); // Save current for undo

    _restoreState(state);
  }

  _CanvasState _getCurrentState() {
    return _CanvasState(
      cards: List<DraggableCard>.from(_cards.map((c) => c.copy())),
      connections: List<Connection>.from(_connections.map((c) => c.copy())),
      scale: _currentScale,
      offset: _offset,
    );
  }

  void _restoreState(_CanvasState state) {
    setState(() {
      _cards = List<DraggableCard>.from(state.cards.map((c) => c.copy()));
      _connections = List<Connection>.from(state.connections.map((c) => c.copy()));
      _currentScale = state.scale;
      _offset = state.offset;
      _updateConnectedPorts();
    });
  }

  // Convert global position to canvas local position
  Offset _globalToLocal(Offset globalPosition) {
    final RenderBox? canvasBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (canvasBox != null) {
      return canvasBox.globalToLocal(globalPosition);
    }
    return globalPosition;
  }

  // Connection handling methods
  void _onPortDragStart(int cardIndex, PortSide side, Offset globalPosition, {int? setVarIndex}) {
    // globalPosition is the actual port center from GlobalKey - use it directly
    final localPos = _globalToLocal(globalPosition);

    print('🔵 DRAG START: Card=$cardIndex, Side=$side, SetVarIndex=$setVarIndex');

    setState(() {
      _dragFromCardIndex = cardIndex;
      _dragFromPortSide = side;
      _dragFromSetVarIndex = setVarIndex;
      _dragStartPosition = localPos;
      _dragCurrentPosition = localPos;
    });
  }

  void _onPortDragUpdate(Offset globalPosition) {
    final localPosition = _globalToLocal(globalPosition);
    setState(() {
      _dragCurrentPosition = localPosition;
      // Update nearest port for visual feedback
      _nearestTargetPort = _findNearestPort(localPosition);
    });
  }

  void _onPortDragEnd(int fromCardIndex, PortSide fromSide) {
    // Use the cached nearest target port
    final targetPort = _nearestTargetPort;

    if (targetPort != null && _dragFromPortSide != null && _dragFromCardIndex != null) {
      final toCardIndex = targetPort['cardIndex'] as int;
      final toSide = targetPort['side'] as PortSide;
      final toSetVarIndex = targetPort['setVarIndex'] as int?;

      // Validate connection: no same-side connections and no self-connections
      if (_dragFromPortSide != toSide && _dragFromCardIndex != toCardIndex) {
        final fromPortSuffix = _dragFromSetVarIndex != null ? '_$_dragFromSetVarIndex' : '';
        final toPortSuffix = toSetVarIndex != null ? '_$toSetVarIndex' : '';
        final connectionId = '${_dragFromCardIndex}_${_dragFromPortSide!.name}${fromPortSuffix}_${toCardIndex}_${toSide.name}${toPortSuffix}';
        final reverseId = '${toCardIndex}_${toSide.name}${toPortSuffix}_${_dragFromCardIndex}_${_dragFromPortSide!.name}${fromPortSuffix}';

        final alreadyExists = _connections.any((c) => c.id == connectionId || c.id == reverseId);

        if (!alreadyExists) {
          final connection = Connection(
            id: connectionId,
            fromCardIndex: _dragFromCardIndex!,
            toCardIndex: toCardIndex,
            fromSide: _dragFromPortSide!,
            toSide: toSide,
            fromPortIndex: _dragFromSetVarIndex,
            toPortIndex: toSetVarIndex,
          );

          setState(() {
            _connections.add(connection);
            final fromPortKey = _dragFromSetVarIndex != null
                ? '${_dragFromCardIndex}_${_dragFromPortSide!.name}_$_dragFromSetVarIndex'
                : '${_dragFromCardIndex}_${_dragFromPortSide!.name}';
            final toPortKey = toSetVarIndex != null
                ? '${toCardIndex}_${toSide.name}_$toSetVarIndex'
                : '${toCardIndex}_${toSide.name}';
            _connectedPorts.add(fromPortKey);
            _connectedPorts.add(toPortKey);
          });
          _saveToHistory(); // ADD THIS
        }
      }
    }

    // Reset drag state
    setState(() {
      _dragFromCardIndex = null;
      _dragFromPortSide = null;
      _dragFromSetVarIndex = null;
      _dragStartPosition = null;
      _dragCurrentPosition = null;
      _nearestTargetPort = null;
    });
  }

  // Find nearest port to given position
  Map<String, dynamic>? _findNearestPort(Offset position) {
    const double snapDistance = 50.0; // Maximum distance to snap to a port
    const double baseCardHeight = 156.0; // Title + TextField + Transition sections
    const double setVarRowHeight = 36.0;

    double minDistance = snapDistance;
    Map<String, dynamic>? nearestPort;

    for (int i = 0; i < _cards.length; i++) {
      // Skip the card we're dragging from
      if (i == _dragFromCardIndex) continue;

      final card = _cards[i];

      // Calculate dynamic card height based on SetVariables
      final cardHeight = baseCardHeight + (card.setVariables.length * setVarRowHeight);

      // Calculate card bounds in screen coordinates
      // Card widget has 12px left padding for the port, so actual card starts at +12
      final cardX = card.position.dx * _currentScale + _offset.dx + (12.0 * _currentScale);
      final cardY = card.position.dy * _currentScale + _offset.dy;
      final cardRect = Rect.fromLTWH(
        cardX,
        cardY,
        200.0 * _currentScale, // Actual card width (without port padding)
        cardHeight * _currentScale,
      );

      // Check left port (always exists)
      if (_dragFromPortSide != PortSide.left) {
        final portPos = _getPortPosition(card, PortSide.left);
        if (portPos != null) {
          final distance = (portPos - position).distance;

          // If cursor is inside the card, snap to left port
          if (cardRect.contains(position)) {
            print('🎯 Card $i hit! pos=$position rect=$cardRect');
            nearestPort = {
              'cardIndex': i,
              'side': PortSide.left,
              'position': portPos,
            };
            return nearestPort; // Immediately return when inside card
          }

          if (distance < minDistance) {
            minDistance = distance;
            nearestPort = {
              'cardIndex': i,
              'side': PortSide.left,
              'position': portPos,
            };
          }
        }
      }

      // Check right ports on SetVariable rows - use ACTUAL positions from GlobalKeys
      if (_dragFromPortSide != PortSide.right) {
        final setVarCount = card.setVariables.length;
        for (int setVarIdx = 0; setVarIdx < setVarCount; setVarIdx++) {
          // Get actual position from GlobalKey (dynamic, not calculated)
          final portPos = _getActualPortPosition(i, setVarIdx);
          if (portPos != null) {
            final distance = (portPos - position).distance;
            if (distance < minDistance) {
              minDistance = distance;
              nearestPort = {
                'cardIndex': i,
                'side': PortSide.right,
                'setVarIndex': setVarIdx,
                'position': portPos,
              };
            }
          }
        }
      }
    }

    return nearestPort;
  }

  void _onConnectionHover(Offset position) {
    // Don't change hover state while dragging from port
    if (_dragFromCardIndex != null) return;

    // If no connections, nothing to hover
    if (_connections.isEmpty) return;

    String? foundConnectionId;

    // Check all connections for hover
    for (var connection in _connections) {
      if (connection.fromCardIndex >= _cards.length ||
          connection.toCardIndex >= _cards.length) {
        continue;
      }

      final fromCard = _cards[connection.fromCardIndex];
      final toCard = _cards[connection.toCardIndex];
      final fromPos = _getPortPosition(fromCard, connection.fromSide, portIndex: connection.fromPortIndex);
      final toPos = _getPortPosition(toCard, connection.toSide, portIndex: connection.toPortIndex);

      if (fromPos == null || toPos == null) continue;

      // Check if near the connection line using orthogonal path calculation
      if (_isPointNearOrthogonalPath(position, fromPos, toPos,
          connection.fromSide, connection.toSide, threshold: 15.0)) {
        foundConnectionId = connection.id;
        break;
      }
    }

    // Only update if changed
    if (_hoveredConnectionId != foundConnectionId) {
      setState(() {
        _hoveredConnectionId = foundConnectionId;
      });
    }
  }

  // Orthogonal path proximity check (matches connection_painter logic)
  bool _isPointNearOrthogonalPath(Offset point, Offset start, Offset end,
      PortSide fromSide, PortSide toSide, {double threshold = 15.0}) {
    // Get all segments of the orthogonal path
    final segments = _getOrthogonalPathSegments(start, end, fromSide, toSide);

    // Check distance to each segment
    for (final segment in segments) {
      if (_distanceToLineSegment(point, segment[0], segment[1]) < threshold) {
        return true;
      }
    }
    return false;
  }

  // Get line segments of the orthogonal path
  List<List<Offset>> _getOrthogonalPathSegments(Offset start, Offset end,
      PortSide fromSide, PortSide toSide) {
    final gap = 40.0 * _currentScale;
    final clearance = 120.0 * _currentScale;

    final startExtendX = (fromSide == PortSide.right)
        ? start.dx + gap
        : start.dx - gap;

    final endExtendX = (toSide == PortSide.left)
        ? end.dx - gap
        : end.dx + gap;

    // Simple case: Right port to Left port with enough space
    if (fromSide == PortSide.right && toSide == PortSide.left && end.dx > start.dx + gap * 2) {
      final midX = (start.dx + end.dx) / 2;
      return [
        [start, Offset(midX, start.dy)],
        [Offset(midX, start.dy), Offset(midX, end.dy)],
        [Offset(midX, end.dy), end],
      ];
    } else {
      final minY = start.dy < end.dy ? start.dy : end.dy;
      final maxY = start.dy > end.dy ? start.dy : end.dy;

      double routeY;
      if (minY > clearance) {
        routeY = minY - clearance;
      } else {
        routeY = maxY + clearance;
      }

      return [
        [start, Offset(startExtendX, start.dy)],
        [Offset(startExtendX, start.dy), Offset(startExtendX, routeY)],
        [Offset(startExtendX, routeY), Offset(endExtendX, routeY)],
        [Offset(endExtendX, routeY), Offset(endExtendX, end.dy)],
        [Offset(endExtendX, end.dy), end],
      ];
    }
  }

  // Distance from point to line segment
  double _distanceToLineSegment(Offset point, Offset lineStart, Offset lineEnd) {
    final dx = lineEnd.dx - lineStart.dx;
    final dy = lineEnd.dy - lineStart.dy;
    final lengthSquared = dx * dx + dy * dy;

    if (lengthSquared == 0) {
      return (point - lineStart).distance;
    }

    final t = ((point.dx - lineStart.dx) * dx + (point.dy - lineStart.dy) * dy) / lengthSquared;
    final clampedT = t.clamp(0.0, 1.0);

    final closest = Offset(
      lineStart.dx + clampedT * dx,
      lineStart.dy + clampedT * dy,
    );

    return (point - closest).distance;
  }

  void _deleteConnection(String connectionId) {
    setState(() {
      _connections.removeWhere((c) => c.id == connectionId);
      _hoveredConnectionId = null; // Clear hover state after delete
      // Update connected ports
      _updateConnectedPorts();
    });
    _saveToHistory();
  }

  void _updateConnectedPorts() {
    _connectedPorts.clear();
    for (var connection in _connections) {
      // Include port index for SetVariable ports
      final fromKey = connection.fromPortIndex != null
          ? '${connection.fromCardIndex}_${connection.fromSide.name}_${connection.fromPortIndex}'
          : '${connection.fromCardIndex}_${connection.fromSide.name}';
      final toKey = connection.toPortIndex != null
          ? '${connection.toCardIndex}_${connection.toSide.name}_${connection.toPortIndex}'
          : '${connection.toCardIndex}_${connection.toSide.name}';
      _connectedPorts.add(fromKey);
      _connectedPorts.add(toKey);
    }
  }
  @override
  void initState() {
    super.initState();
    _twoFingerZoomHandler = TwoFingerZoomHandler(
      onScaleChanged: _updateScale,
      onStatusChanged: (String status) {}, // Empty callback since we're not using status
      minScale: minScale,
      maxScale: maxScale,
    );
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.sizeOf(context).width < 700) {
      _isRightPanelVisible = false;
    }
    // On large screens, it stays true (initial value)
  }
  void _updateScale(double newScale) {
    setState(() {
      _currentScale = newScale;
    });
    // Schedule multiple rebuilds to ensure GlobalKey positions update after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      }
    });
  }

  void _zoomIn() {
    setState(() {
      _currentScale = (_currentScale + zoomStep).clamp(minScale, maxScale);
    });
    // Schedule multiple rebuilds to ensure GlobalKey positions update after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      }
    });
  }

  void _zoomOut() {
    setState(() {
      _currentScale = (_currentScale - zoomStep).clamp(minScale, maxScale);
    });
    // Schedule multiple rebuilds to ensure GlobalKey positions update after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      }
    });
  }
  String? _getIconKeyFromData(IconData icon) {
    final node = NodeTypes.all.firstWhere(
          (n) => n['icon'] == icon,
      orElse: () => {'key': null}, // ✅ returns Map, not null
    );
    return node['key'] as String?;
  }

  // Handle adding a card and show dialog for "Add Event"
  void _handleAddCard(String title, IconData icon) async {
    final iconKey = _getIconKeyFromData(icon);

    if (title == 'Add Event') {
      final result = await showDialog<List<ConfiguredEvent>>(
        context: context,
        builder: (context) => const AddEventDialog(),
      );

      if (result != null && result.isNotEmpty) {
        // Format all events into a readable string
        final eventSummaries = result.map((e) {
          final type = _getEventDisplayName(e.type);
          final config = e.config.entries.map((entry) => '${entry.key}: ${entry.value}').join(', ');
          return '$type: $config';
        }).join('\n\n');

        final card = DraggableCard(
          position: Offset(100 + (_cards.length * 50), 100 + (_cards.length * 50)),
          title: 'Add Event',
          iconKey: iconKey,
          textContent: eventSummaries, // Show all configured events
          zIndex: _cards.length,
        );

        setState(() {
          _cards.add(card);
        });
        _saveToHistory(); // ADD THIS
      }
    } else {
      // Normal card addition
      final card = DraggableCard(
        position: Offset(100 + (_cards.length * 50), 100 + (_cards.length * 50)),
        title: title,
        iconKey: iconKey,
        textContent: '',
        zIndex: _cards.length,
      );
      setState(() {
        _cards.add(card);
      });
    }
  }

// Helper for event display name (can be shared or duplicated)
  String _getEventDisplayName(String type) {
    switch (type) {
      case 'calendar': return 'Calendar';
      case 'sheetspeed': return 'Sheetspeed';
      case 'customize': return 'Custom';
      default: return type;
    }
  }
  void _addCard() {
    setState(() {
      _cards.add(
        DraggableCard(
          position: Offset(100 + (_cards.length * 50), 100 + (_cards.length * 50)),
          title: 'Card ${_cards.length + 1}',
          // color: Colors.primaries[_cards.length % Colors.primaries.length].withOpacity(0.8),
          zIndex: _cards.length, // Set z-index to current length
        ),
      );
    });
  }

  // Bring a card to the front (highest z-index)
  void _bringToFront(int index) {
    if (index >= 0 && index < _cards.length) {
      int maxZIndex = 0;
      if (_cards.isNotEmpty) {
        maxZIndex = _cards.map((card) => card.zIndex).reduce((a, b) => a > b ? a : b);
      }
      setState(() {
        _cards[index].zIndex = maxZIndex + 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(
        onBack: () => Navigator.of(context).pop(),
        title: 'Agent Automation',
        onTestAgent: () {
          _rightPanelKey.currentState?.showTestAgentTab();
        },
        onExport: _exportCanvas,
        onImport: () async {
          final content = await _loadFromFile();
          if (content.isNotEmpty) _importCanvas(content);
        },
      ),

      body: Stack(
        children: [
          // Main canvas content
          Row(
            children: [

              if (MediaQuery.sizeOf(context).width >= 700)
                CanvasSidebar(
                    onAddCard: _handleAddCard,
                    cardCount: _cards.length,
                  onToggleMagicBuilder: _toggleMagicBuilder, // 👈 ADD THIS

                ),

              // Canvas area
              Expanded(
                child: MouseRegion(
                  cursor: _draggedCardIndex != null
                      ? SystemMouseCursors.grabbing   // card is being dragged → grabbing
                      : (!_isCanvasLocked && !_isMagicBuilderActive)
                      ? SystemMouseCursors.grab   // canvas is draggable → grab
                      : SystemMouseCursors.basic, // locked or Magic Builder → default
                  child: Listener(
                    onPointerDown: (PointerDownEvent event) {
                      if (_isMagicBuilderActive || _isCanvasLocked) return;
                      _twoFingerZoomHandler.handlePointerDown(event);
                    },
                    onPointerMove: (PointerMoveEvent event) {
                  
                      if (_isMagicBuilderActive || _isCanvasLocked) return;
                  
                      _twoFingerZoomHandler.handlePointerMove(event, _currentScale);
                    },
                    onPointerUp: (PointerUpEvent event) {
                      _twoFingerZoomHandler.handlePointerUp(event);
                      // Create connection if we have a valid target
                      if (_nearestTargetPort != null && _dragFromPortSide != null && _dragFromCardIndex != null) {
                        final targetPort = _nearestTargetPort!;
                        final toCardIndex = targetPort['cardIndex'] as int;
                        final toSide = targetPort['side'] as PortSide;
                        final toSetVarIndex = targetPort['setVarIndex'] as int?;
                  
                        if (_dragFromPortSide != toSide && _dragFromCardIndex != toCardIndex) {
                          final fromPortSuffix = _dragFromSetVarIndex != null ? '_$_dragFromSetVarIndex' : '';
                          final toPortSuffix = toSetVarIndex != null ? '_$toSetVarIndex' : '';
                          final connectionId = '${_dragFromCardIndex}_${_dragFromPortSide!.name}${fromPortSuffix}_${toCardIndex}_${toSide.name}${toPortSuffix}';
                          final reverseId = '${toCardIndex}_${toSide.name}${toPortSuffix}_${_dragFromCardIndex}_${_dragFromPortSide!.name}${fromPortSuffix}';
                  
                          final alreadyExists = _connections.any((c) => c.id == connectionId || c.id == reverseId);
                  
                          if (!alreadyExists) {
                            setState(() {
                              _connections.add(Connection(
                                id: connectionId,
                                fromCardIndex: _dragFromCardIndex!,
                                toCardIndex: toCardIndex,
                                fromSide: _dragFromPortSide!,
                                toSide: toSide,
                                fromPortIndex: _dragFromSetVarIndex,
                                toPortIndex: toSetVarIndex,
                              ));
                              final fromPortKey = _dragFromSetVarIndex != null
                                  ? '${_dragFromCardIndex}_${_dragFromPortSide!.name}_$_dragFromSetVarIndex'
                                  : '${_dragFromCardIndex}_${_dragFromPortSide!.name}';
                              final toPortKey = toSetVarIndex != null
                                  ? '${toCardIndex}_${toSide.name}_$toSetVarIndex'
                                  : '${toCardIndex}_${toSide.name}';
                              _connectedPorts.add(fromPortKey);
                              _connectedPorts.add(toPortKey);
                            });
                          }
                        }
                      }
                      // Reset drag state
                      setState(() {
                        _dragFromCardIndex = null;
                        _dragFromPortSide = null;
                        _dragFromSetVarIndex = null;
                        _dragStartPosition = null;
                        _dragCurrentPosition = null;
                        _nearestTargetPort = null;
                      });
                    },
                    onPointerCancel: (PointerCancelEvent event) {
                      if (_isMagicBuilderActive || _isCanvasLocked) return;
                  
                      _twoFingerZoomHandler.handlePointerCancel(event);
                      // Global cleanup: reset any stuck drag state
                      if (_dragStartPosition != null) {
                        setState(() {
                          _dragFromCardIndex = null;
                          _dragFromPortSide = null;
                          _dragFromSetVarIndex = null;
                          _dragStartPosition = null;
                          _dragCurrentPosition = null;
                          _nearestTargetPort = null;
                        });
                      }
                    },
                    onPointerSignal: (PointerSignalEvent event) {
                      if (_isMagicBuilderActive || _isCanvasLocked) return; // 👈 blocks scroll zoom
                  
                      // Optional: if you have custom scroll-to-zoom logic, handle it here
                      // Otherwise, just returning early is enough to block it
                    },
                    child: InteractiveViewer(
                  
                      transformationController: TransformationController(),
                      boundaryMargin: const EdgeInsets.all(double.infinity),
                      // scaleEnabled: false,
                      // panEnabled: false,
                      // panEnabled: !_isMagicBuilderActive,
                      // scaleEnabled: !_isMagicBuilderActive,
                      panEnabled: !_isMagicBuilderActive && !_isCanvasLocked,
                      scaleEnabled: !_isMagicBuilderActive && !_isCanvasLocked,
                      minScale: 0.01,
                      maxScale: 100.0,
                      onInteractionStart: (ScaleStartDetails details) {
                        _startFocalPoint = details.focalPoint;
                        _startOffset = _offset;
                        _startScale = _currentScale;
                      },
                      onInteractionEnd: (ScaleEndDetails details) {
                        // After zoom/pan gesture ends, force rebuild to update GlobalKey positions
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {});
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) setState(() {});
                            });
                          }
                        });
                      },
                      onInteractionUpdate: (ScaleUpdateDetails details) {
                        if (_isMagicBuilderActive || _isCanvasLocked) return;
                  
                        if (_twoFingerZoomHandler.fingerCount < 2) {
                          setState(() {
                            // Calculate new scale
                            double newScale = (_startScale * details.scale).clamp(minScale, maxScale);
                  
                            // Calculate the focal point in the coordinate system before scaling
                            Offset focalPointBefore = (_startFocalPoint - _startOffset) / _startScale;
                  
                            // Calculate focal point delta for panning
                            Offset focalPointDelta = details.focalPoint - _startFocalPoint;
                  
                            Offset focalPointAfter = (details.focalPoint - (_startOffset + focalPointDelta)) / newScale;
                  
                            // Adjust offset to keep focal point stable during zoom
                            Offset zoomAdjustment = (focalPointAfter - focalPointBefore) * newScale;
                  
                            // Apply pan and zoom
                            _offset = _startOffset + focalPointDelta + zoomAdjustment;
                            _currentScale = newScale;
                          });
                        }
                      },
                      child: MouseRegion(
                        onHover: (event) {
                          // Use localPosition since we're inside the canvas
                          _onConnectionHover(event.localPosition);
                        },
                        child: Stack(
                          key: _canvasKey,
                          children: [
                            // Infinite dot grid background
                            InfiniteDotGrid(
                              scale: _currentScale,
                              offset: _offset,
                            ),
                  
                            // Connection lines layer - BEHIND cards
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  key: ValueKey('connections_${_connections.length}_${_currentScale}_${_offset.dx}_${_offset.dy}_${_cards.map((c) => '${c.position.dx}_${c.position.dy}').join('_')}'),
                                  painter: ConnectionPainter(
                                    connections: _connections,
                                    cards: _cards,
                                    scale: _currentScale,
                                    offset: _offset,
                                    hoveredConnectionId: _hoveredConnectionId,
                                    actualPortPositions: _buildActualPortPositions(),
                                  ),
                                ),
                              ),
                            ),
                            // Draggable cards - sort by z-index to control stacking order
                            ..._getSortedCards(),
                  
                            // Drag line layer - ON TOP of cards
                            if (_dragStartPosition != null)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    painter: DragLinePainter(
                                      dragStartPosition: _dragStartPosition,
                                      dragCurrentPosition: _dragCurrentPosition,
                                      nearestPortPosition: _nearestTargetPort?['position'] as Offset?,
                                      scale: _currentScale,
                                    ),
                                  ),
                                ),
                              ),
                            // Delete button for hovered connection
                            if (_hoveredConnectionId != null)
                              _buildDeleteButton(),
                  
                            if (_isMagicBuilderActive)
                              FrostedGlassOverlay(
                                isVisible: true,
                                onClose: () {
                                  setState(() {
                                    _isMagicBuilderActive = false;
                                  });
                                },
                              ),
                            // if (_isMagicBuilderActive)
                            //   FrostedGlassOverlay(
                            //     isVisible: true,
                            //     onTapOutside: () {
                            //       setState(() {
                            //         _isMagicBuilderActive = false;
                            //       });
                            //     },
                            //   ),
                            if (MediaQuery.sizeOf(context).width < 700)
                              Positioned(
                                top: 16,
                                left: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.purple.shade200),
                                  ),
                                  child: TextButton(
                                    onPressed: _toggleMagicBuilder, // 👈 connect to toggle
                  
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                      foregroundColor: Colors.purple,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      minimumSize: Size.zero,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.auto_fix_high, size: 16, color: Colors.purple),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'Magic Builder',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.purple,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              top: 16,
                              right: 16,
                              child: FloatingActionButton(
                                heroTag: 'right-panel-toggle',
                                mini: true,
                                onPressed: _toggleRightPanel,
                                child: Icon(_isRightPanelVisible ? Icons.close : Icons.menu),
                              ),
                            ),
                  
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              ),

              // Right Panel

              // // 👇 Show panel only if visible

              // Right Panel
              if (_isRightPanelVisible)
                RightPanel(
                  key: _rightPanelKey, //
                  onClose: _toggleRightPanel,
                  selectedCard: _selectedCard,
                  globalSettings: _globalSettings,
                  onNodeSettingsChanged: () => setState(() {}),
                  onGlobalSettingsChanged: () => setState(() {}), // 👈 ADD
                ),
            ],
          ),
          if (MediaQuery.sizeOf(context).width < 400)
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'right-panel-toggle',
                mini: true,
                onPressed: _toggleRightPanel,
                child: Icon(_isRightPanelVisible ? Icons.close : Icons.menu),
              ),
            ),

          // Bottom toolbar positioned at the bottom center
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child:
              CanvasBottomToolbar(
                onZoomIn: _zoomIn,
                onZoomOut: _zoomOut,
                onResetView: () {
                  setState(() {
                    _currentScale = 1.0;
                    _offset = Offset.zero;
                  });
                },
                onUndo: _history.isNotEmpty ? _undo : null,
                onRedo: _redoStack.isNotEmpty ? _redo : null,
                onAddCardWithType: _handleAddCard,
                onLockToggle: () {
                  setState(() {
                    _isCanvasLocked = !_isCanvasLocked;
                  });
                },
                isCanvasLocked: _isCanvasLocked, // 👈 pass current state
              ),
              // CanvasBottomToolbar(
              //   onZoomIn: _zoomIn,
              //   onZoomOut: _zoomOut,
              //   onResetView: () {
              //     setState(() {
              //       _currentScale = 1.0;
              //       _offset = Offset.zero;
              //     });
              //     _saveToHistory(); // optional: if you want reset view to be undoable
              //   },
              //   onUndo: _history.isNotEmpty ? _undo : null,
              //   onRedo: _redoStack.isNotEmpty ? _redo : null,
              //   onAddCardWithType: _handleAddCard,
              // ),
            ),
          ),


        ],
      ),
    );
  }

  // Helper method to get cards sorted by z-index
  List<Widget> _getSortedCards() {
    List<int> sortedIndices = List.generate(_cards.length, (index) => index)
      ..sort((a, b) => _cards[a].zIndex.compareTo(_cards[b].zIndex));

    return sortedIndices.map((index) {
      DraggableCard card = _cards[index];

      return Positioned(
        left: card.position.dx * _currentScale + _offset.dx,
        top: card.position.dy * _currentScale + _offset.dy,
        child: Transform.scale(
          scale: _currentScale,
          alignment: Alignment.topLeft, // Scale from top-left to match position calculation
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedCard = _cards[index]; // 👈 select this card
                _hoveredCardIndex = index;     // 👈 keep it highlighted
              });
            },
            child: DraggableCardWidget(
              key: ValueKey('${card.id}_${card.textContent}'),
              card: card,
              index: index,
              isSelected: _selectedCard == _cards[index],
              currentScale: _currentScale, // Pass current scale to the card
              onPanStart: (details) {
                setState(() {
                  _draggedCardIndex = index;
                });
                _bringToFront(index); // Bring to front when dragging starts
              },
              onCardSelected: () {
                setState(() {
                  _selectedCard = _cards[index]; // 👈 switch right panel to this card
                });
              },
             // part that calculates how the mouse moves a card node at a given zoom level is inside
            
              onPanUpdate: (details) {
                if (_draggedCardIndex == index) {
                  setState(() {
                    double baseSensitivity = 1.0;
                    double sensitivity = baseSensitivity;
                    if (_currentScale < 0.8) {
                      // Zoomed out: reduce sensitivity but not too much
                      sensitivity = 0.5 + 0.7 * (_currentScale); // Ranges from 0.3 at 0.1x to 1.0 at 1.0x
                    } else {
                      // Zoomed in: can be more sensitive
                      sensitivity = 1.0 + 0.5 * (_currentScale - 1.0); // Gradually increases beyond 1.0x
                    }
            
                    // Apply sensitivity to the movement
                    Offset adjustedDelta = details.delta * sensitivity;
                    _cards[index].position += adjustedDelta;
                  });
                }
              },
              onPanEnd: (details) {
                setState(() {
                  _draggedCardIndex = null;
                });
                _saveToHistory(); //  ADD THIS
            
              },
              onHoverEnter: () {
                _hoveredCardIndex = index;

                _bringToFront(index); // Bring to front when hovering
              },

              onHoverExit: () {
                setState(() {
                  _hoveredCardIndex = null;
                });
              },
              isConnectedAndHovered: _getConnectedCardIndices().contains(index) || index == _hoveredCardIndex,
              onPortDragStart: _onPortDragStart,
              onPortDragUpdate: _onPortDragUpdate,
              onPortDragEnd: _onPortDragEnd,
              connectedPorts: _connectedPorts,
              getPortKey: _getPortKey,
              targetedPortKey: _nearestTargetPort != null && _nearestTargetPort!['setVarIndex'] != null
                  ? '${_nearestTargetPort!['cardIndex']}_${_nearestTargetPort!['setVarIndex']}'
                  : null,
              isTargetedForConnection: _nearestTargetPort != null &&
                  _nearestTargetPort!['cardIndex'] == index &&
                  _nearestTargetPort!['side'] == PortSide.left,
              onSetVariableRemoved: (cardIndex, setVarIndex) {
                setState(() {
                  // Remove connections that use this SetVariable port and rebuild others with updated indices
                  _connections = _connections
                      .where((c) =>
                          !(c.fromCardIndex == cardIndex && c.fromPortIndex == setVarIndex) &&
                          !(c.toCardIndex == cardIndex && c.toPortIndex == setVarIndex))
                      .map((c) => Connection(
                            id: c.id,
                            fromCardIndex: c.fromCardIndex,
                            toCardIndex: c.toCardIndex,
                            fromSide: c.fromSide,
                            toSide: c.toSide,
                            fromPortIndex: (c.fromCardIndex == cardIndex && c.fromPortIndex != null && c.fromPortIndex! > setVarIndex)
                                ? c.fromPortIndex! - 1
                                : c.fromPortIndex,
                            toPortIndex: (c.toCardIndex == cardIndex && c.toPortIndex != null && c.toPortIndex! > setVarIndex)
                                ? c.toPortIndex! - 1
                                : c.toPortIndex,
                          ))
                      .toList();
            
                  // Rebuild _connectedPorts from remaining connections
                  _connectedPorts.clear();
                  for (final c in _connections) {
                    final fromPortKey = c.fromPortIndex != null
                        ? '${c.fromCardIndex}_${c.fromSide.name}_${c.fromPortIndex}'
                        : '${c.fromCardIndex}_${c.fromSide.name}';
                    final toPortKey = c.toPortIndex != null
                        ? '${c.toCardIndex}_${c.toSide.name}_${c.toPortIndex}'
                        : '${c.toCardIndex}_${c.toSide.name}';
                    _connectedPorts.add(fromPortKey);
                    _connectedPorts.add(toPortKey);
                  }
                });
              },
              onDelete: () => _deleteCard(index),
              onDuplicate: () => _duplicateCard(index),
            ),
          ),
        ),
      );
    }).toList();
  }

  // Build delete button for hovered connection
  Widget _buildDeleteButton() {
    if (_hoveredConnectionId == null) return const SizedBox.shrink();

    // Find the connection to get midpoint (with safety check)
    final connectionIndex = _connections.indexWhere((c) => c.id == _hoveredConnectionId);
    if (connectionIndex == -1) return const SizedBox.shrink();

    final connection = _connections[connectionIndex];

    if (connection.fromCardIndex >= _cards.length ||
        connection.toCardIndex >= _cards.length) {
      return const SizedBox.shrink();
    }

    final fromCard = _cards[connection.fromCardIndex];
    final toCard = _cards[connection.toCardIndex];
    final fromPos = _getPortPosition(fromCard, connection.fromSide, portIndex: connection.fromPortIndex);
    final toPos = _getPortPosition(toCard, connection.toSide, portIndex: connection.toPortIndex);

    if (fromPos == null || toPos == null) return const SizedBox.shrink();

    // Calculate midpoint along the actual orthogonal path
    final midpoint = _getOrthogonalPathMidpoint(
      fromPos, toPos, connection.fromSide, connection.toSide);

    return Positioned(
      left: midpoint.dx - 20,
      top: midpoint.dy - 20,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _deleteConnection(_hoveredConnectionId!);
          },
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Offset? _getPortPosition(DraggableCard card, PortSide side, {int? portIndex}) {
    // MUST MATCH connection_painter.dart EXACTLY!
    const double leftPadding = 12.0;
    const double cardWidth = 200.0;
    const double leftPortX = 12.0;
    const double leftPortY = 92.0 + 12.0;  // top: 92 + half of 24px port = 104
    const double rightPortX = leftPadding + cardWidth;  // = 212

    // Measured from actual widget structure:
    const double sectionsTotal = 24.0 + 100.0 + 32.0;  // = 156
    const double setVarRowHeight = 36.0;
    const double portCenterOffsetInRow = 20.0;

    final cardX = card.position.dx * _currentScale + _offset.dx;
    final cardY = card.position.dy * _currentScale + _offset.dy;

    double portX;
    double portY;

    if (side == PortSide.left) {
      portX = cardX + leftPortX * _currentScale;
      portY = cardY + leftPortY * _currentScale;
    } else {
      portX = cardX + rightPortX * _currentScale;
      if (portIndex != null) {
        final portYInCard = sectionsTotal + (portIndex * setVarRowHeight) + portCenterOffsetInRow;
        portY = cardY + portYInCard * _currentScale;
      } else {
        portY = cardY + leftPortY * _currentScale;
      }
    }

    return Offset(portX, portY);
  }
  Offset _getOrthogonalPathMidpoint(Offset start, Offset end, PortSide fromSide, PortSide toSide) {
    final gap = 40.0 * _currentScale;
    final clearance = 120.0 * _currentScale;

    final startExtendX = (fromSide == PortSide.right)
        ? start.dx + gap
        : start.dx - gap;

    final endExtendX = (toSide == PortSide.left)
        ? end.dx - gap
        : end.dx + gap;

    // Simple case: Right port to Left port with enough space
    if (fromSide == PortSide.right && toSide == PortSide.left && end.dx > start.dx + gap * 2) {
      final midX = (start.dx + end.dx) / 2;
      // Midpoint is on the vertical segment
      return Offset(midX, (start.dy + end.dy) / 2);
    } else {
      // Complex routing - midpoint is on the horizontal routing segment
      final minY = start.dy < end.dy ? start.dy : end.dy;
      final maxY = start.dy > end.dy ? start.dy : end.dy;

      double routeY;
      if (minY > clearance) {
        routeY = minY - clearance;
      } else {
        routeY = maxY + clearance;
      }
      return Offset((startExtendX + endExtendX) / 2, routeY);
    }
  }
  Set<int> _getConnectedCardIndices() {
    if (_hoveredCardIndex == null) return {};
    final Set<int> indices = {};
    for (final conn in _connections) {
      if (conn.fromCardIndex == _hoveredCardIndex!) {
        indices.add(conn.toCardIndex);
      } else if (conn.toCardIndex == _hoveredCardIndex!) {
        indices.add(conn.fromCardIndex);
      }
    }
    return indices;
  }

}

