

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/draggable_card.dart';
import '../models/connection.dart';
import 'node_settings_tab.dart';
import 'port_widget.dart';

// Draggable Card Widget
class DraggableCardWidget extends StatefulWidget {
  final DraggableCard card;
  final int index;
  final bool isSelected;
  final double currentScale;
  final Function(DragStartDetails) onPanStart;
  final Function(DragUpdateDetails) onPanUpdate;
  final Function(DragEndDetails) onPanEnd;
  final VoidCallback? onHoverEnter;
  final GlobalKey? cardKey;
  final VoidCallback? onHoverExit;
  final bool isConnectedAndHovered;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;
  final VoidCallback? onCardSelected;

  // Connection-related callbacks
  final Function(int cardIndex, PortSide side, Offset globalPosition, {int? setVarIndex})? onPortDragStart;
  final Function(Offset globalPosition)? onPortDragUpdate;
  final Function(int cardIndex, PortSide side)? onPortDragEnd;
  final Function(int cardIndex, PortSide side)? onPortHover;
  final Set<String>? connectedPorts;
  final GlobalKey Function(int cardIndex, int setVarIndex)? getPortKey;
  final String? targetedPortKey;  // "cardIndex_setVarIndex" of port being targeted
  final bool isTargetedForConnection;  // True when this card's left port is being targeted
  final Function(int cardIndex, int setVarIndex)? onSetVariableRemoved;

  const DraggableCardWidget({
    Key? key,
    required this.card,
    required this.index,
    required this.currentScale,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    this.onHoverEnter,
    this.cardKey,
    this.onPortDragStart,
    this.onPortDragUpdate,
    this.onPortDragEnd,
    this.onPortHover,
    this.connectedPorts,
    this.getPortKey,
    this.targetedPortKey,
    this.isTargetedForConnection = false,
    this.isConnectedAndHovered = false, // 👈 add this
    this.onSetVariableRemoved,
    this.onHoverExit,
    this.isSelected = false,
    this.onDelete,
    this.onCardSelected,
    this.onDuplicate,
  }) : super(key: key);
  @override
  State<DraggableCardWidget> createState() => _DraggableCardWidgetState();
}
// In the DraggableCardWidget class
class _DraggableCardWidgetState extends State<DraggableCardWidget> {
  bool _isHovering = false;
  // late TextEditingController _titleController;
  Offset? _lastMousePosition;
  late TextEditingController _textController;
  int? _hoveredSetVariableIndex;
  bool _leftPortHovering = false;
  bool _isDraggingFromPort = false;
  final GlobalKey _leftPortKey = GlobalKey();
  bool _isDragging = false;


  // Inside _DraggableCardWidgetState
  bool get _shouldShowTextArea {
    // Use iconKey for robustness (recommended)
    return widget.card.iconKey == 'conversation' || widget.card.iconKey == 'sms';
  }

  Offset? _getLeftPortCenter() {
    final RenderBox? box = _leftPortKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      final size = box.size;
      return box.localToGlobal(Offset(size.width / 2, size.height / 2));
    }
    return null;
  }

  @override
  void didUpdateWidget(DraggableCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.textContent != widget.card.textContent) {
      _textController.text = widget.card.textContent;
    }
  }
  late FocusNode _textFocusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.card.textContent);
    _textFocusNode = FocusNode();
    _textFocusNode.addListener(() {
      if (_textFocusNode.hasFocus) {
        widget.onCardSelected?.call();
      }
    });
  }

  @override
  void dispose() {
    _textFocusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _addSetVariable() {
    // Add a new set variable with default values
    widget.card.addSetVariable('variable_name', 'variable_value');
    setState(() {
      // Rebuild to show the new set variable
    });
  }
  void _removeSetVariable(int index) {
    // Notify parent to remove associated connections
    widget.onSetVariableRemoved?.call(widget.index, index);
    widget.card.removeSetVariable(index);
    setState(() {
      // Rebuild to remove the set variable
    });
  }
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: _isDragging
          ? SystemMouseCursors.grabbing
          : SystemMouseCursors.grab,
      onEnter: (event) {
        _lastMousePosition = event.position;
        setState(() => _isHovering = true);
        // Bring card to front when mouse enters
        if (widget.onHoverEnter != null) {
          widget.onHoverEnter!();
        }
      },
      onExit: (event) {
        setState(() => _isHovering = false);
        widget.onHoverExit?.call(); // 👈 ADD THIS
        _hoveredSetVariableIndex = null; // Reset when card is no longer hovered
      },
      onHover: (event) {
        // Only print if mouse moved significantly
        if (_lastMousePosition == null ||
            (_lastMousePosition! - event.position).distance > 5.0) {
          _lastMousePosition = event.position;
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main card content with gesture detection (not Positioned so Stack can size from it)
          Padding(
            padding: const EdgeInsets.only(left: 12), // Space for left port
            child: GestureDetector(

              onPanStart: (details) {
                setState(() {
                  _isDragging = true; // 👈
                });
                widget.onPanStart(details);
              },
              onPanUpdate: (details) {
                widget.onPanUpdate(details);
              },
              onPanEnd: (details) {
                setState(() {
                  _isDragging = false; // 👈
                });
                widget.onPanEnd(details);
              },
              onPanCancel: () {
                setState(() {
                  _isDragging = false; // 👈
                });
              },
                child: Container(
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),

                    border: Border.all(
                      color: (widget.isSelected || _isHovering || widget.isConnectedAndHovered)
                          ? Colors.black
                          : Colors.grey,
                      width: (widget.isSelected || _isHovering || widget.isConnectedAndHovered)
                          ? 2
                          : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // This ensures the column only takes needed space
                    crossAxisAlignment: CrossAxisAlignment.stretch, // Makes children stretch to full width
                    children: [
                      // Main title container
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade300,
                            ),
                          ),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left side: Label icon and title
                            Flexible(
                              child: Row(
                                children: [
                                  Icon(
                                    widget.card.getIconData(),
                                    size: 16,
                                    color: Colors.grey,
                                  ),                                const SizedBox(width: 4),
                                  Text(
                                    widget.card.title,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Right side: Horizontal dots icon
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_horiz,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              onSelected: (String result) {
                                if (result == 'duplicate') {
                                  widget.onDuplicate?.call();
                                } else if (result == 'delete') {
                                  widget.onDelete?.call();
                                }
                              },

                              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                PopupMenuItem<String>(
                                  value: 'duplicate',
                                  child: Row(
                                    children: [
                                      Icon(Icons.content_copy, size: 14),
                                      SizedBox(width: 8),
                                      Text('Duplicate', style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 14),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Always show a content area with consistent height
                      Container(
                        constraints: const BoxConstraints(minHeight: 100),
                        child: _shouldShowTextArea
                            ? Container(
                          color: Colors.grey[100],
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: _textController,
                            focusNode: _textFocusNode, // 👈 will define this below

                            decoration: InputDecoration(
                              hintText: 'Enter text...',
                              border: InputBorder.none,
                            ),
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                            minLines: 5,
                            maxLines: 8,
                            onChanged: (value) => widget.card.textContent = value,
                          ),
                        )
                            : Center(
                          child: Text(
                            'Configure ${widget.card.title}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), // Reduced vertical padding
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          border: Border(
                            top: BorderSide(
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Transition',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add,
                                size: 16,
                              ),
                              onPressed: _addSetVariable,
                              padding: EdgeInsets.zero, // Remove default padding
                              constraints: BoxConstraints.tightFor(width: 24, height: 24), // Smaller button
                            ),
                          ],
                        ),
                      ),
                      // Only add set variables if there are any
                      if (widget.card.setVariables.isNotEmpty) ...[
                        ...widget.card.setVariables.asMap().entries.map((entry) {
                          int i = entry.key;
                          return SetVariableWidget(
                            setVariable: entry.value,
                            index: i,
                            cardIndex: widget.index,
                            onRemove: _removeSetVariable,
                            cardHovering: _isHovering,
                            isHovered: _hoveredSetVariableIndex == i,
                            onHover: (bool isHovered) {
                              setState(() {
                                if (isHovered) {
                                  _hoveredSetVariableIndex = i;
                                } else if (_hoveredSetVariableIndex == i) {
                                  _hoveredSetVariableIndex = null;
                                }
                              });
                            },
                            onPortDragStart: widget.onPortDragStart != null
                                ? (cardIdx, side, pos, setVarIdx) {
                                    // Forward to parent with setVarIndex info
                                    widget.onPortDragStart?.call(cardIdx, side, pos, setVarIndex: setVarIdx);
                                  }
                                : null,
                            onPortDragUpdate: widget.onPortDragUpdate,
                            onPortDragEnd: widget.onPortDragEnd != null
                                ? (cardIdx, side, setVarIdx) {
                                    widget.onPortDragEnd?.call(cardIdx, side);
                                  }
                                : null,
                            connectedPorts: widget.connectedPorts,
                            portKey: widget.getPortKey?.call(widget.index, i),
                            isTargeted: widget.targetedPortKey == '${widget.index}_$i',
                          );
                        }).toList(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          // Left Port - centered on the left border of the card Container
          // Card Container starts at x=12 (due to Padding), port width=24, so center at x=12-12=0
            Positioned(
              left: 0,
              top: 92,
              child: MouseRegion(

                cursor: SystemMouseCursors.move,
                onEnter: (_) => setState(() => _leftPortHovering = true),
                onExit: (_) => setState(() => _leftPortHovering = false),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) {
                    setState(() => _isDraggingFromPort = true);
                    final portCenter = _getLeftPortCenter() ?? details.globalPosition;
                    widget.onPortDragStart?.call(widget.index, PortSide.left, portCenter);
                  },
                  onPanUpdate: (details) {
                    widget.onPortDragUpdate?.call(details.globalPosition);
                  },
                  onPanEnd: (details) {
                    setState(() => _isDraggingFromPort = false);
                    widget.onPortDragEnd?.call(widget.index, PortSide.left);
                  },
                  onPanCancel: () {
                    setState(() => _isDraggingFromPort = false);
                    widget.onPortDragEnd?.call(widget.index, PortSide.left);
                  },
                  child: Container(
                    key: _leftPortKey,
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    child: PortWidget(
                      side: PortSide.left,
                      isHovering: _leftPortHovering || _isHovering || widget.isTargetedForConnection,
                      isConnected: widget.connectedPorts?.contains('${widget.index}_left') ?? false,
                      isDragging: _isDraggingFromPort,
                      isTargeted: widget.isTargetedForConnection,
                    ),
                  ),
                ),
              ),
            ),
          // Right ports are now on each SetVariable row, not here
        ],
      ),
    );
  }
}
// Set Variable Widget
class SetVariableWidget extends StatefulWidget {
  final SetVariable setVariable;
  final int index;
  final int cardIndex;
  final Function(int) onRemove;
  final bool cardHovering;
  final bool isHovered;
  final Function(bool) onHover;
  // Port callbacks
  final Function(int cardIndex, PortSide side, Offset globalPosition, int setVarIndex)? onPortDragStart;
  final Function(Offset globalPosition)? onPortDragUpdate;
  final Function(int cardIndex, PortSide side, int setVarIndex)? onPortDragEnd;
  final Set<String>? connectedPorts;
  final GlobalKey? portKey;  // External key for position tracking
  final bool isTargeted;  // True when this port is being targeted by a drag

  const SetVariableWidget({
    super.key,
    required this.setVariable,
    required this.index,
    required this.cardIndex,
    required this.onRemove,
    required this.cardHovering,
    required this.isHovered,
    required this.onHover,
    this.onPortDragStart,
    this.onPortDragUpdate,
    this.onPortDragEnd,
    this.connectedPorts,
    this.portKey,
    this.isTargeted = false,
  });
  @override
  State<SetVariableWidget> createState() => _SetVariableWidgetState();
}
class _SetVariableWidgetState extends State<SetVariableWidget> {
  bool _portHovering = false;
  bool _isDraggingFromPort = false;

  // Use external key if provided, otherwise create internal one
  GlobalKey get _portKey => widget.portKey ?? _internalKey;
  final GlobalKey _internalKey = GlobalKey();

  Offset? _getPortCenter() {
    final RenderBox? box = _portKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      final size = box.size;
      return box.localToGlobal(Offset(size.width / 2, size.height / 2));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) => widget.onHover(true),
      onExit: (event) => widget.onHover(false),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade400,
                ),
              ),
            ),
            child: Row(
              children: [
                // Show close icon only when the specific set variable is hovered
                if (widget.isHovered)
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      widget.onRemove(widget.index);
                    },
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints.tightFor(width: 20, height: 20),
                  )
                else
                  Container(width: 28),
                const SizedBox(width: 4),
                Icon(
                  Icons.settings,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Set Variable ${widget.index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          // Right port - centered on the right border of the card
          Positioned(
            right: -12,  // Container is inside card with no right padding, so -12 centers 24px port on border
            top: 8,
            child: MouseRegion(
              cursor: SystemMouseCursors.move,
              onEnter: (_) => setState(() => _portHovering = true),
              onExit: (_) => setState(() => _portHovering = false),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (details) {
                  setState(() => _isDraggingFromPort = true);
                  // Use actual port center position instead of cursor position
                  final portCenter = _getPortCenter() ?? details.globalPosition;
                  widget.onPortDragStart?.call(
                    widget.cardIndex, PortSide.right, portCenter, widget.index);
                },
                onPanUpdate: (details) {
                  widget.onPortDragUpdate?.call(details.globalPosition);
                },
                onPanEnd: (details) {
                  setState(() => _isDraggingFromPort = false);
                  widget.onPortDragEnd?.call(widget.cardIndex, PortSide.right, widget.index);
                },
                onPanCancel: () {
                  setState(() => _isDraggingFromPort = false);
                  widget.onPortDragEnd?.call(widget.cardIndex, PortSide.right, widget.index);
                },
                child: Container(
                  key: _portKey,
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  child: PortWidget(
                    side: PortSide.right,
                    isHovering: _portHovering,
                    isConnected: widget.connectedPorts?.contains(
                      '${widget.cardIndex}_right_${widget.index}') ?? false,
                    isDragging: _isDraggingFromPort,
                    isTargeted: widget.isTargeted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
