import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'helpers/html_stub.dart' as html if (dart.library.html) 'dart:html';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'node/constants/node_types.dart';
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

/// Canvas state for undo/redo functionality
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

  _CanvasState copy() => _CanvasState(
    cards: List<DraggableCard>.from(cards.map((c) => c.copy())),
    connections: List<Connection>.from(connections.map((c) => c.copy())),
    scale: scale,
    offset: offset,
  );
}

class AgentAutomationScreen extends StatefulWidget {
  const AgentAutomationScreen({super.key, required String agentName});

  @override
  State<AgentAutomationScreen> createState() => _AgentAutomationScreenState();
}

class _AgentAutomationScreenState extends State<AgentAutomationScreen> {
  // Canvas transform state
  double _currentScale = 1.0;
  Offset _offset = Offset.zero;
  
  // Variables for Gesture Detection
  double _baseScale = 1.0;
  Offset _baseOffset = Offset.zero;
  Offset? _lastFocalPoint;

  // UI state
  bool _isRightPanelVisible = true;
  bool _isMagicBuilderActive = false;
  bool _isCanvasLocked = false;
  DraggableCard? _selectedCard;
  int? _hoveredCardIndex;
  String? _hoveredConnectionId;
  
  // Drag state - using ValueNotifier for efficient updates
  int? _draggedCardIndex;
  final ValueNotifier<Offset> _currentDragOffset = ValueNotifier(Offset.zero);
  
  // Connection drag state
  int? _dragFromCardIndex;
  PortSide? _dragFromPortSide;
  int? _dragFromSetVarIndex;
  Offset? _dragStartPosition;
  Offset? _dragCurrentPosition;
  Map<String, dynamic>? _nearestTargetPort;
  Set<String> _connectedPorts = {};
  
  // Port keys for position tracking
  final Map<String, GlobalKey> _portKeys = {};
  
  // Undo/Redo
  final List<_CanvasState> _history = [];
  final List<_CanvasState> _redoStack = [];
  Timer? _historyDebounceTimer;
  
  // Canvas key and settings
  final GlobalKey _canvasKey = GlobalKey();
  final _rightPanelKey = GlobalKey<RightPanelState>();
  GlobalSettings _globalSettings = GlobalSettings();
  
  // Cards and connections
  List<DraggableCard> _cards = [
    DraggableCard(position: Offset(100, 100), title: 'Card 1', zIndex: 0),
    DraggableCard(position: Offset(300, 200), title: 'Card 2', zIndex: 1),
    DraggableCard(position: Offset(500, 400), title: 'Card 3', zIndex: 2),
  ];
  List<Connection> _connections = [];

  // Constants
  static const double minScale = 0.1;
  static const double maxScale = 5.0;
  static const double zoomStep = 0.2;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _historyDebounceTimer?.cancel();
    _currentDragOffset.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.sizeOf(context).width < 700) {
      _isRightPanelVisible = false;
    }
  }

  // ==================== ZOOM & PAN HELPERS ====================

  void _updateScaleAtPoint(double newScale, Offset focalPoint) {
    // Clamp scale
    newScale = newScale.clamp(minScale, maxScale);
    if ((_currentScale - newScale).abs() < 0.001) return;

    // Calculate the world coordinate of the focal point before zoom
    final worldFocalPoint = (focalPoint - _offset) / _currentScale;

    // Update scale
    setState(() {
      _currentScale = newScale;
      // Adjust offset to keep the world point under the focal point
      _offset = focalPoint - (worldFocalPoint * newScale);
    });
  }

  void _zoomIn() {
    final size = MediaQuery.sizeOf(context);
    final center = Offset(size.width / 2, size.height / 2);
    _updateScaleAtPoint(_currentScale + zoomStep, center);
  }

  void _zoomOut() {
    final size = MediaQuery.sizeOf(context);
    final center = Offset(size.width / 2, size.height / 2);
    _updateScaleAtPoint(_currentScale - zoomStep, center);
  }

  void _zoomTowardPoint(double deltaScale, Offset focalPoint) {
    _updateScaleAtPoint(_currentScale + deltaScale, focalPoint);
  }

  Offset _globalToLocal(Offset globalPosition) {
    final RenderBox? canvasBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    return canvasBox?.globalToLocal(globalPosition) ?? globalPosition;
  }

  // ==================== GESTURE HANDLERS (FIXED) ====================

  void _onPointerSignal(PointerSignalEvent event) {
    if (_isMagicBuilderActive || _isCanvasLocked) return;

    if (event is PointerScaleEvent) {
      // Trackpad Pinch Zoom
      // PointerScaleEvent gives a 'scale' relative to 1.0 per event usually
      double newScale = _currentScale * event.scale;
      _updateScaleAtPoint(newScale, event.localPosition);
    } else if (event is PointerScrollEvent) {
      // Mouse Wheel Zoom (with Ctrl) or Trackpad Scroll
      // Adjust sensitivity as needed
      if (event.scrollDelta.dy != 0) {
        double scaleChange = event.scrollDelta.dy < 0 ? 0.1 : -0.1;
         // If Ctrl is pressed, or on some trackpads, treat scroll as zoom
        _zoomTowardPoint(scaleChange, event.localPosition);
      }
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    if (_isMagicBuilderActive || _isCanvasLocked) return;
    _baseScale = _currentScale;
    _baseOffset = _offset;
    _lastFocalPoint = details.localFocalPoint;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_isMagicBuilderActive || _isCanvasLocked) return;

    setState(() {
      // 1. Handle Zoom
      if (details.scale != 1.0) {
        final newScale = (_baseScale * details.scale).clamp(minScale, maxScale);
        
        // Math to zoom towards focal point:
        // currentFocal = (focal - oldOffset) / oldScale
        // newOffset = focal - currentFocal * newScale
        // This is complex during a continuous gesture, simpler approach:
        
        // Use the difference in focal point for panning + scaling logic
        // But for standard GestureDetector behavior:
        
        // Calculate the "World Point" under the starting focal point
        final worldPoint = (_lastFocalPoint! - _baseOffset) / _baseScale;
        
        _currentScale = newScale;
        // Adjust offset so that worldPoint is still under the current focalPoint
        _offset = details.localFocalPoint - (worldPoint * _currentScale);
      } else {
        // 2. Handle Pan Only (if scale is 1.0)
        final delta = details.localFocalPoint - _lastFocalPoint!;
        _offset += delta;
      }
      
      // Update focal point for next frame
      _lastFocalPoint = details.localFocalPoint;
    });
  }

  // ==================== CARD OPERATIONS ====================

  void _bringToFront(int index) {
    if (index < 0 || index >= _cards.length) return;
    final maxZ = _cards.fold(0, (max, card) => card.zIndex > max ? card.zIndex : max);
    setState(() => _cards[index].zIndex = maxZ + 1);
  }

  void _deleteCard(int cardIndex) {
    setState(() {
      _connections.removeWhere((c) => c.fromCardIndex == cardIndex || c.toCardIndex == cardIndex);
      _cards.removeAt(cardIndex);
      
      for (int i = 0; i < _connections.length; i++) {
        final c = _connections[i];
        _connections[i] = Connection(
          id: c.id,
          fromCardIndex: c.fromCardIndex > cardIndex ? c.fromCardIndex - 1 : c.fromCardIndex,
          toCardIndex: c.toCardIndex > cardIndex ? c.toCardIndex - 1 : c.toCardIndex,
          fromSide: c.fromSide,
          toSide: c.toSide,
          fromPortIndex: c.fromPortIndex,
          toPortIndex: c.toPortIndex,
        );
      }
      _updateConnectedPorts();
    });
    _saveToHistory();
  }

  void _duplicateCard(int cardIndex) {
    final original = _cards[cardIndex];
    final newTitle = _generateCopyTitle(original.title);
    
    final copy = DraggableCard(
      position: Offset(original.position.dx + 30, original.position.dy + 30),
      title: newTitle,
      iconKey: original.iconKey,
      textContent: original.textContent,
      isCollapsed: original.isCollapsed,
      zIndex: _cards.length,
    )..setSetVariables(List<SetVariable>.from(
        original.setVariables.map((sv) => SetVariable(name: sv.name, value: sv.value))
    ));

    setState(() => _cards.add(copy));
    _saveToHistory();
  }

  String _generateCopyTitle(String title) {
    final pattern = RegExp(r' \(copy(?: (\d+))?\)$');
    final match = pattern.firstMatch(title);
    if (match == null) return '$title (copy)';
    final num = match.group(1);
    if (num == null) return title.replaceFirst(pattern, ' (copy 2)');
    return title.replaceFirst(pattern, ' (copy ${int.parse(num) + 1})');
  }

  // ==================== PORT & CONNECTION HANDLING ====================

  GlobalKey _getPortKey(int cardIndex, int setVarIndex) {
    final key = '${cardIndex}_$setVarIndex';
    return _portKeys.putIfAbsent(key, () => GlobalKey());
  }

  void _onPortDragStart(int cardIndex, PortSide side, Offset globalPosition, {int? setVarIndex}) {
    // When using Manual Scale/Offset, globalToLocal usually returns the coordinate 
    // relative to the Stack. Since our Stack is full screen, this is (Pointer - WindowTopLeft).
    // But we need "Canvas Local" for drag line drawing which is handled by CustomPaint inside Stack.
    
    // The incoming globalPosition is Screen Coordinates.
    // _globalToLocal converts it to coordinates relative to the Stack (which is the Canvas Viewport).
    final localPos = _globalToLocal(globalPosition);

    setState(() {
      _dragFromCardIndex = cardIndex;
      _dragFromPortSide = side;
      _dragFromSetVarIndex = setVarIndex;
      _dragStartPosition = localPos;
      _dragCurrentPosition = localPos;
    });
  }

  void _onPortDragUpdate(Offset globalPosition) {
    final localPos = _globalToLocal(globalPosition);
    setState(() {
      _dragCurrentPosition = localPos;
      _nearestTargetPort = _findNearestPort(localPos);
    });
  }

  void _onPortDragEnd(int fromCardIndex, PortSide fromSide) {
    if (_nearestTargetPort != null && _dragFromPortSide != null && _dragFromCardIndex != null) {
      final toCardIndex = _nearestTargetPort!['cardIndex'] as int;
      final toSide = _nearestTargetPort!['side'] as PortSide;
      final toSetVarIndex = _nearestTargetPort!['setVarIndex'] as int?;

      if (_dragFromPortSide != toSide && _dragFromCardIndex != toCardIndex) {
        final fromSuffix = _dragFromSetVarIndex != null ? '_$_dragFromSetVarIndex' : '';
        final toSuffix = toSetVarIndex != null ? '_$toSetVarIndex' : '';
        final connId = '${_dragFromCardIndex}_${_dragFromPortSide!.name}${fromSuffix}_${toCardIndex}_${toSide.name}${toSuffix}';
        final reverseId = '${toCardIndex}_${toSide.name}${toSuffix}_${_dragFromCardIndex}_${_dragFromPortSide!.name}${fromSuffix}';

        if (!_connections.any((c) => c.id == connId || c.id == reverseId)) {
          setState(() {
            _connections.add(Connection(
              id: connId,
              fromCardIndex: _dragFromCardIndex!,
              toCardIndex: toCardIndex,
              fromSide: _dragFromPortSide!,
              toSide: toSide,
              fromPortIndex: _dragFromSetVarIndex,
              toPortIndex: toSetVarIndex,
            ));
            _updateConnectedPorts();
          });
          _saveToHistory();
        }
      }
    }
    _resetDragState();
  }

  void _resetDragState() {
    setState(() {
      _dragFromCardIndex = null;
      _dragFromPortSide = null;
      _dragFromSetVarIndex = null;
      _dragStartPosition = null;
      _dragCurrentPosition = null;
      _nearestTargetPort = null;
    });
  }

  Map<String, dynamic>? _findNearestPort(Offset position) {
    const snapDistance = 50.0;
    const baseCardHeight = 156.0;
    const setVarRowHeight = 36.0;

    double minDistance = snapDistance;
    Map<String, dynamic>? nearestPort;

    for (int i = 0; i < _cards.length; i++) {
      if (i == _dragFromCardIndex) continue;

      final card = _cards[i];
      final cardHeight = baseCardHeight + (card.setVariables.length * setVarRowHeight);
      
      // NOTE: Using manual scale math consistent with Positioned widgets
      final cardX = card.position.dx * _currentScale + _offset.dx + (12.0 * _currentScale);
      final cardY = card.position.dy * _currentScale + _offset.dy;
      final cardRect = Rect.fromLTWH(cardX, cardY, 200.0 * _currentScale, cardHeight * _currentScale);

      if (_dragFromPortSide != PortSide.left) {
        final portPos = _getPortPosition(card, PortSide.left);
        if (portPos != null) {
          if (cardRect.contains(position)) {
            return {'cardIndex': i, 'side': PortSide.left, 'position': portPos};
          }
          final distance = (portPos - position).distance;
          if (distance < minDistance) {
            minDistance = distance;
            nearestPort = {'cardIndex': i, 'side': PortSide.left, 'position': portPos};
          }
        }
      }

      if (_dragFromPortSide != PortSide.right) {
        for (int setVarIdx = 0; setVarIdx < card.setVariables.length; setVarIdx++) {
          final portPos = _getPortPosition(card, PortSide.right, portIndex: setVarIdx);
          if (portPos != null) {
            final distance = (portPos - position).distance;
            if (distance < minDistance) {
              minDistance = distance;
              nearestPort = {'cardIndex': i, 'side': PortSide.right, 'setVarIndex': setVarIdx, 'position': portPos};
            }
          }
        }
      }
    }
    return nearestPort;
  }

  Offset? _getPortPosition(DraggableCard card, PortSide side, {int? portIndex}) {
    const leftPortX = 12.0, leftPortY = 104.0;
    const rightPortX = 212.0, sectionsTotal = 156.0, setVarRowHeight = 36.0, portCenterOffset = 20.0;

    final cardX = card.position.dx * _currentScale + _offset.dx;
    final cardY = card.position.dy * _currentScale + _offset.dy;

    if (side == PortSide.left) {
      return Offset(cardX + leftPortX * _currentScale, cardY + leftPortY * _currentScale);
    } else {
      final portY = portIndex != null 
          ? sectionsTotal + (portIndex * setVarRowHeight) + portCenterOffset
          : leftPortY;
      return Offset(cardX + rightPortX * _currentScale, cardY + portY * _currentScale);
    }
  }

  void _updateConnectedPorts() {
    _connectedPorts.clear();
    for (final c in _connections) {
      final fromKey = c.fromPortIndex != null 
          ? '${c.fromCardIndex}_${c.fromSide.name}_${c.fromPortIndex}'
          : '${c.fromCardIndex}_${c.fromSide.name}';
      final toKey = c.toPortIndex != null 
          ? '${c.toCardIndex}_${c.toSide.name}_${c.toPortIndex}'
          : '${c.toCardIndex}_${c.toSide.name}';
      _connectedPorts.add(fromKey);
      _connectedPorts.add(toKey);
    }
  }

  void _deleteConnection(String connectionId) {
    setState(() {
      _connections.removeWhere((c) => c.id == connectionId);
      _hoveredConnectionId = null;
      _updateConnectedPorts();
    });
    _saveToHistory();
  }

  Set<int> _getConnectedCardIndices() {
    if (_hoveredCardIndex == null) return {};
    final indices = <int>{};
    for (final c in _connections) {
      if (c.fromCardIndex == _hoveredCardIndex) indices.add(c.toCardIndex);
      else if (c.toCardIndex == _hoveredCardIndex) indices.add(c.fromCardIndex);
    }
    return indices;
  }

  // ==================== HISTORY (UNDO/REDO) ====================

  void _saveToHistory() {
    _redoStack.clear();
    _historyDebounceTimer?.cancel();
    _historyDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _history.add(_CanvasState(
        cards: List<DraggableCard>.from(_cards.map((c) => c.copy())),
        connections: List<Connection>.from(_connections.map((c) => c.copy())),
        scale: _currentScale,
        offset: _offset,
      ));
      if (_history.length > 50) _history.removeAt(0);
    });
  }

  void _undo() {
    if (_history.isEmpty) return;
    _redoStack.add(_getCurrentState());
    _restoreState(_history.removeLast());
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    _history.add(_getCurrentState());
    _restoreState(_redoStack.removeLast());
  }

  _CanvasState _getCurrentState() => _CanvasState(
    cards: List<DraggableCard>.from(_cards.map((c) => c.copy())),
    connections: List<Connection>.from(_connections.map((c) => c.copy())),
    scale: _currentScale,
    offset: _offset,
  );

  void _restoreState(_CanvasState state) {
    setState(() {
      _cards = List<DraggableCard>.from(state.cards.map((c) => c.copy()));
      _connections = List<Connection>.from(state.connections.map((c) => c.copy()));
      _currentScale = state.scale;
      _offset = state.offset;
      _updateConnectedPorts();
    });
  }

  // ==================== ADD CARD ====================

  String? _getIconKeyFromData(IconData icon) {
    final node = NodeTypes.all.firstWhere(
      (n) => n['icon'] == icon,
      orElse: () => {'key': null},
    );
    return node['key'] as String?;
  }

  void _handleAddCard(String title, IconData icon) async {
    final iconKey = _getIconKeyFromData(icon);

    if (title == 'Add Event') {
      final result = await showDialog<List<ConfiguredEvent>>(
        context: context,
        builder: (_) => const AddEventDialog(),
      );
      if (result != null && result.isNotEmpty) {
        final eventSummaries = result.map((e) {
          final type = _getEventDisplayName(e.type);
          final config = e.config.entries.map((entry) => '${entry.key}: ${entry.value}').join(', ');
          return '$type: $config';
        }).join('\n\n');

        setState(() => _cards.add(DraggableCard(
          position: Offset(100 + (_cards.length * 50), 100 + (_cards.length * 50)),
          title: 'Add Event',
          iconKey: iconKey,
          textContent: eventSummaries,
          zIndex: _cards.length,
        )));
        _saveToHistory();
      }
    } else {
      setState(() => _cards.add(DraggableCard(
        position: Offset(100 + (_cards.length * 50), 100 + (_cards.length * 50)),
        title: title,
        iconKey: iconKey,
        textContent: '',
        zIndex: _cards.length,
      )));
      _saveToHistory();
    }
  }

  String _getEventDisplayName(String type) {
    switch (type) {
      case 'calendar': return 'Calendar';
      case 'sheetspeed': return 'Sheetspeed';
      case 'customize': return 'Custom';
      default: return type;
    }
  }

  // ==================== EXPORT/IMPORT ====================

  void _toggleMagicBuilder() => setState(() => _isMagicBuilderActive = !_isMagicBuilderActive);
  void _toggleRightPanel() => setState(() => _isRightPanelVisible = !_isRightPanelVisible);

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
      'language': _globalSettings.language,
      'opt_out_sensitive_data_storage': false,
      'global_settings': _globalSettings.toJson(),
      'data_storage_setting': 'everything',
      'canvas_data': {
        'cards': _cards.map((card) => card.toJson()).toList(),
        'connections': _connections.map((conn) => conn.toJson()).toList(),
        'canvas_scale': _currentScale,
        'canvas_offset': {'dx': _offset.dx, 'dy': _offset.dy},
      },
      'post_call_analysis_data': [],
    };
    await _saveToFile(const JsonEncoder.withIndent('  ').convert(exportData));
  }

  void _importCanvas(String jsonString) {
    try {
      final data = json.decode(jsonString) as Map<String, dynamic>;
      if (data['global_settings'] != null) {
        _globalSettings = GlobalSettings.fromJson(data['global_settings']);
      }
      if (data['canvas_data'] != null) {
        final canvasData = data['canvas_data'];
        setState(() {
          _cards = (canvasData['cards'] as List?)
              ?.map((j) => DraggableCard.fromJson(j))
              .toList() ?? [];
          _connections = (canvasData['connections'] as List?)
              ?.map((j) => Connection.fromJson(j))
              .toList() ?? [];
          _currentScale = (canvasData['canvas_scale'] as num?)?.toDouble() ?? 1.0;
          final offsetData = canvasData['canvas_offset'] as Map<String, dynamic>? ?? {};
          _offset = Offset(
            (offsetData['dx'] as num?)?.toDouble() ?? 0.0,
            (offsetData['dy'] as num?)?.toDouble() ?? 0.0,
          );
          _updateConnectedPorts();
        });
      }
    } catch (e) {
      debugPrint('Error importing canvas: $e');
    }
  }

  Future<void> _saveToFile(String content) async {
    if (kIsWeb) {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Canvas exported successfully')),
        );
      }
    } else {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/canvas_export.json');
        await file.writeAsString(content);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Canvas exported to: ${file.path}')),
          );
        }
      } catch (e) {
        debugPrint('Error saving file: $e');
      }
    }
  }

  Future<String> _loadFromFile() async {
    if (kIsWeb) {
      final input = html.FileUploadInputElement()..accept = '.json';
      final completer = Completer<String>();
      input.onChange.listen((event) {
        final files = input.files;
        if (files != null && files.isNotEmpty) {
          final reader = html.FileReader();
          reader.onLoadEnd.listen((_) => completer.complete(reader.result as String));
          reader.readAsText(files.first);
        } else {
          completer.complete('');
        }
      });
      input.click();
      return completer.future;
    } else {
      try {
        final directory = await getApplicationDocumentsDirectory();
        return await File('${directory.path}/canvas_export.json').readAsString();
      } catch (e) {
        debugPrint('Error loading file: $e');
        return '';
      }
    }
  }

  // ==================== BUILD METHOD ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(
        onBack: () => Navigator.of(context).pop(),
        title: 'Agent Automation',
        onTestAgent: () => _rightPanelKey.currentState?.showTestAgentTab(),
        onExport: _exportCanvas,
        onImport: () async {
          final content = await _loadFromFile();
          if (content.isNotEmpty) _importCanvas(content);
        },
      ),
      body: Stack(
        children: [
          Row(
            children: [
              if (MediaQuery.sizeOf(context).width >= 700)
                CanvasSidebar(
                  onAddCard: _handleAddCard,
                  cardCount: _cards.length,
                  onToggleMagicBuilder: _toggleMagicBuilder,
                ),
              Expanded(child: _buildCanvas()),
              if (_isRightPanelVisible)
                RightPanel(
                  key: _rightPanelKey,
                  onClose: _toggleRightPanel,
                  selectedCard: _selectedCard,
                  globalSettings: _globalSettings,
                  onNodeSettingsChanged: () => setState(() {}),
                  onGlobalSettingsChanged: () => setState(() {}),
                ),
            ],
          ),
          _buildBottomToolbar(),
        ],
      ),
    );
  }

  Widget _buildCanvas() {
    // REPLACED InteractiveViewer with Listener + GestureDetector 
    // to handle manual scale/offset calculations correctly.
    return Listener(
      onPointerSignal: _onPointerSignal,
      child: GestureDetector(
        onScaleStart: _handleScaleStart,
        onScaleUpdate: _handleScaleUpdate,
        // Container ensures hit tests work on empty space
        child: Container(
          color: Colors.transparent, 
          child: ClipRect(
            child: MouseRegion(
              cursor: _draggedCardIndex != null
                  ? SystemMouseCursors.grabbing
                  : (!_isCanvasLocked && !_isMagicBuilderActive)
                      ? SystemMouseCursors.grab
                      : SystemMouseCursors.basic,
              child: MouseRegion(
                onHover: (event) => _onConnectionHover(event.localPosition),
                child: Stack(
                  key: _canvasKey,
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // Background grid
                    Positioned.fill(
                      child: InfiniteDotGrid(
                        scale: _currentScale,
                        offset: _offset,
                      ),
                    ),
                    
                    // Connection lines layer
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: IgnorePointer(
                          child: ValueListenableBuilder<Offset>(
                            valueListenable: _currentDragOffset,
                            builder: (_, dragOffset, __) => CustomPaint(
                              painter: ConnectionPainter(
                                connections: _connections,
                                cards: _cards,
                                scale: _currentScale,
                                offset: _offset,
                                hoveredConnectionId: _hoveredConnectionId,
                                draggedCardIndex: _draggedCardIndex,
                                dragOffset: dragOffset,
                              ),
                              isComplex: true,
                              willChange: _draggedCardIndex != null,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Cards layer
                    ..._buildSortedCards(),
                    
                    // Drag line layer
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
                    if (_hoveredConnectionId != null) _buildDeleteButton(),
                    
                    // Magic Builder overlay
                    if (_isMagicBuilderActive)
                      FrostedGlassOverlay(
                        isVisible: true,
                        onClose: () => setState(() => _isMagicBuilderActive = false),
                      ),
                    
                    // Mobile Magic Builder button
                    if (MediaQuery.sizeOf(context).width < 700)
                      Positioned(
                        top: 16,
                        left: 16,
                        child: _buildMobileMenuButton(),
                      ),
                    
                    // Right panel toggle
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
    );
  }

  // ==================== HELPERS ====================

  void _onConnectionHover(Offset position) {
    if (_dragFromCardIndex != null || _connections.isEmpty) return;
    
    String? foundId;
    for (final c in _connections) {
      if (c.fromCardIndex >= _cards.length || c.toCardIndex >= _cards.length) continue;
      final fromPos = _getPortPosition(_cards[c.fromCardIndex], c.fromSide, portIndex: c.fromPortIndex);
      final toPos = _getPortPosition(_cards[c.toCardIndex], c.toSide, portIndex: c.toPortIndex);
      if (fromPos != null && toPos != null && _isNearConnection(position, fromPos, toPos, c.fromSide, c.toSide)) {
        foundId = c.id;
        break;
      }
    }
    
    if (_hoveredConnectionId != foundId) {
      setState(() => _hoveredConnectionId = foundId);
    }
  }

  bool _isNearConnection(Offset point, Offset start, Offset end, PortSide fromSide, PortSide toSide) {
    const threshold = 15.0;
    final gap = 40.0 * _currentScale;
    final clearance = 120.0 * _currentScale;
    
    final startX = fromSide == PortSide.right ? start.dx + gap : start.dx - gap;
    final endX = toSide == PortSide.left ? end.dx - gap : end.dx + gap;
    
    List<List<Offset>> segments;
    if (fromSide == PortSide.right && toSide == PortSide.left && end.dx > start.dx + gap * 2) {
      final midX = (start.dx + end.dx) / 2;
      segments = [
        [start, Offset(midX, start.dy)],
        [Offset(midX, start.dy), Offset(midX, end.dy)],
        [Offset(midX, end.dy), end],
      ];
    } else {
      final minY = start.dy < end.dy ? start.dy : end.dy;
      final maxY = start.dy > end.dy ? start.dy : end.dy;
      final routeY = minY > clearance ? minY - clearance : maxY + clearance;
      segments = [
        [start, Offset(startX, start.dy)],
        [Offset(startX, start.dy), Offset(startX, routeY)],
        [Offset(startX, routeY), Offset(endX, routeY)],
        [Offset(endX, routeY), Offset(endX, end.dy)],
        [Offset(endX, end.dy), end],
      ];
    }
    
    for (final seg in segments) {
      if (_distanceToSegment(point, seg[0], seg[1]) < threshold) return true;
    }
    return false;
  }

  double _distanceToSegment(Offset point, Offset start, Offset end) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final lenSq = dx * dx + dy * dy;
    if (lenSq == 0) return (point - start).distance;
    final t = ((point.dx - start.dx) * dx + (point.dy - start.dy) * dy) / lenSq;
    final closest = Offset(start.dx + t.clamp(0.0, 1.0) * dx, start.dy + t.clamp(0.0, 1.0) * dy);
    return (point - closest).distance;
  }

  List<Widget> _buildSortedCards() {
    final sortedIndices = List.generate(_cards.length, (i) => i)
      ..sort((a, b) => _cards[a].zIndex.compareTo(_cards[b].zIndex));

    return sortedIndices.map((index) {
      final card = _cards[index];
      
      return Positioned(
        key: ValueKey('card_$index'),
        left: card.position.dx * _currentScale + _offset.dx,
        top: card.position.dy * _currentScale + _offset.dy,
        child: ValueListenableBuilder<Offset>(
          valueListenable: _currentDragOffset,
          builder: (_, dragOffset, child) {
            final effectiveOffset = (_draggedCardIndex == index) ? dragOffset : Offset.zero;
            return Transform.translate(
              offset: effectiveOffset,
              child: child!,
            );
          },
          child: Transform.scale(
            scale: _currentScale,
            alignment: Alignment.topLeft,
            child: _buildCardWidget(card, index),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildCardWidget(DraggableCard card, int index) {
    return GestureDetector(
      child: DraggableCardWidget(
        key: ValueKey('${card.id}_${card.textContent.hashCode}'),
        card: card,
        index: index,
        isSelected: _selectedCard == _cards[index],
        currentScale: _currentScale,
        onPanStart: (details) {
          _draggedCardIndex = index;
          _currentDragOffset.value = Offset.zero;
          _bringToFront(index);
          setState(() {});
        },
        onPanUpdate: (details) {
          if (_draggedCardIndex == index) {
            _currentDragOffset.value += details.delta;
          }
        },
        onPanEnd: (details) {
          if (_draggedCardIndex == index) {
            _cards[index].position += Offset(
              _currentDragOffset.value.dx / _currentScale,
              _currentDragOffset.value.dy / _currentScale,
            );
          }
          _draggedCardIndex = null;
          _currentDragOffset.value = Offset.zero;
          setState(() {});
          _saveToHistory();
        },
        onHoverEnter: () {
          _hoveredCardIndex = index;
          _bringToFront(index);
        },
        onHoverExit: () => setState(() => _hoveredCardIndex = null),
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
            _updateConnectedPorts();
          });
        },
        onDelete: () => _deleteCard(index),
        onDuplicate: () => _duplicateCard(index),
      ),
    );
  }

  Widget _buildDeleteButton() {
    final connIdx = _connections.indexWhere((c) => c.id == _hoveredConnectionId);
    if (connIdx == -1) return const SizedBox.shrink();

    final c = _connections[connIdx];
    if (c.fromCardIndex >= _cards.length || c.toCardIndex >= _cards.length) {
      return const SizedBox.shrink();
    }

    final fromPos = _getPortPosition(_cards[c.fromCardIndex], c.fromSide, portIndex: c.fromPortIndex);
    final toPos = _getPortPosition(_cards[c.toCardIndex], c.toSide, portIndex: c.toPortIndex);
    if (fromPos == null || toPos == null) return const SizedBox.shrink();

    final midpoint = _getOrthogonalMidpoint(fromPos, toPos, c.fromSide, c.toSide);

    return Positioned(
      left: midpoint.dx - 20,
      top: midpoint.dy - 20,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _deleteConnection(_hoveredConnectionId!),
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
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }

  Offset _getOrthogonalMidpoint(Offset start, Offset end, PortSide fromSide, PortSide toSide) {
    final gap = 40.0 * _currentScale;
    final clearance = 120.0 * _currentScale;
    final startX = fromSide == PortSide.right ? start.dx + gap : start.dx - gap;
    final endX = toSide == PortSide.left ? end.dx - gap : end.dx + gap;

    if (fromSide == PortSide.right && toSide == PortSide.left && end.dx > start.dx + gap * 2) {
      return Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    } else {
      final minY = start.dy < end.dy ? start.dy : end.dy;
      final maxY = start.dy > end.dy ? start.dy : end.dy;
      final routeY = minY > clearance ? minY - clearance : maxY + clearance;
      return Offset((startX + endX) / 2, routeY);
    }
  }

  Widget _buildBottomToolbar() {
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: CanvasBottomToolbar(
          onZoomIn: _zoomIn,
          onZoomOut: _zoomOut,
          onResetView: () => setState(() {
            _currentScale = 1.0;
            _offset = Offset.zero;
          }),
          onUndo: _history.isNotEmpty ? _undo : null,
          onRedo: _redoStack.isNotEmpty ? _redo : null,
          onAddCardWithType: _handleAddCard,
          onLockToggle: () => setState(() => _isCanvasLocked = !_isCanvasLocked),
          isCanvasLocked: _isCanvasLocked,
        ),
      ),
    );
  }

  Widget _buildMobileMenuButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: TextButton(
        onPressed: _toggleMagicBuilder,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          foregroundColor: Colors.purple,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: Size.zero,
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_fix_high, size: 16, color: Colors.purple),
            SizedBox(width: 4),
            Text(
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
    );  
  }
}