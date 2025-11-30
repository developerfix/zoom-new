import 'package:flutter/material.dart';
import '../models/draggable_card.dart';
import '../models/connection.dart';
import 'port_widget.dart';

/// High-performance draggable card widget optimized for smooth canvas interactions.
/// Uses RepaintBoundary and minimizes rebuilds during drag operations.

class DraggableCardWidget extends StatefulWidget {
  final DraggableCard card;
  final int index;
  final bool isSelected;
  final double currentScale;
  final Function(DragStartDetails) onPanStart;
  final Function(DragUpdateDetails) onPanUpdate;
  final Function(DragEndDetails) onPanEnd;
  final VoidCallback? onHoverEnter;
  final VoidCallback? onHoverExit;
  final bool isConnectedAndHovered;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;
  final VoidCallback? onCardSelected;
  final Function(int cardIndex, PortSide side, Offset globalPosition, {int? setVarIndex})? onPortDragStart;
  final Function(Offset globalPosition)? onPortDragUpdate;
  final Function(int cardIndex, PortSide side)? onPortDragEnd;
  final Set<String>? connectedPorts;
  final GlobalKey Function(int cardIndex, int setVarIndex)? getPortKey;
  final String? targetedPortKey;
  final bool isTargetedForConnection;
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
    this.onHoverExit,
    this.onPortDragStart,
    this.onPortDragUpdate,
    this.onPortDragEnd,
    this.connectedPorts,
    this.getPortKey,
    this.targetedPortKey,
    this.isTargetedForConnection = false,
    this.isConnectedAndHovered = false,
    this.onSetVariableRemoved,
    this.isSelected = false,
    this.onDelete,
    this.onCardSelected,
    this.onDuplicate,
  }) : super(key: key);

  @override
  State<DraggableCardWidget> createState() => _DraggableCardWidgetState();
}

class _DraggableCardWidgetState extends State<DraggableCardWidget> {
  bool _isHovering = false;
  bool _isDragging = false;
  bool _leftPortHovering = false;
  bool _isDraggingFromPort = false;
  int? _hoveredSetVariableIndex;
  
  late TextEditingController _textController;
  late FocusNode _textFocusNode;
  final GlobalKey _leftPortKey = GlobalKey();

  bool get _shouldShowTextArea =>
      widget.card.iconKey == 'conversation' || widget.card.iconKey == 'sms';

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.card.textContent);
    _textFocusNode = FocusNode()..addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_textFocusNode.hasFocus) widget.onCardSelected?.call();
  }

  @override
  void didUpdateWidget(DraggableCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.textContent != widget.card.textContent) {
      _textController.text = widget.card.textContent;
    }
  }

  @override
  void dispose() {
    _textFocusNode.removeListener(_onFocusChange);
    _textFocusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  Offset? _getLeftPortCenter() {
    final RenderBox? box = _leftPortKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      return box.localToGlobal(Offset(box.size.width / 2, box.size.height / 2));
    }
    return null;
  }

  void _addSetVariable() {
    widget.card.addSetVariable('variable_name', 'variable_value');
    setState(() {});
  }

  void _removeSetVariable(int index) {
    widget.onSetVariableRemoved?.call(widget.index, index);
    widget.card.removeSetVariable(index);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isHighlighted = widget.isSelected || _isHovering || widget.isConnectedAndHovered;
    
    return RepaintBoundary(
      child: MouseRegion(
        cursor: _isDragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
        onEnter: (_) {
          if (!_isHovering) {
            _isHovering = true;
            widget.onHoverEnter?.call();
            setState(() {});
          }
        },
        onExit: (_) {
          if (_isHovering) {
            _isHovering = false;
            _hoveredSetVariableIndex = null;
            widget.onHoverExit?.call();
            setState(() {});
          }
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: GestureDetector(
                onPanStart: (details) {
                  _isDragging = true;
                  setState(() {});
                  widget.onPanStart(details);
                },
                onPanUpdate: widget.onPanUpdate,
                onPanEnd: (details) {
                  _isDragging = false;
                  setState(() {});
                  widget.onPanEnd(details);
                },
                onPanCancel: () {
                  if (_isDragging) {
                    _isDragging = false;
                    setState(() {});
                  }
                },
                child: _buildCardContainer(isHighlighted),
              ),
            ),
            _buildLeftPort(),
          ],
        ),
      ),
    );
  }

  Widget _buildCardContainer(bool isHighlighted) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlighted ? Colors.black : Colors.grey,
          width: isHighlighted ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          _buildContentArea(),
          _buildTransitionSection(),
          ..._buildSetVariables(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              children: [
                Icon(widget.card.getIconData(), size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  widget.card.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz, size: 16, color: Colors.grey[600]),
            onSelected: (result) {
              if (result == 'duplicate') widget.onDuplicate?.call();
              else if (result == 'delete') widget.onDelete?.call();
            },
            itemBuilder: (_) => [
              _buildPopupItem('duplicate', Icons.content_copy, 'Duplicate'),
              _buildPopupItem('delete', Icons.delete, 'Delete'),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, IconData icon, String text) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildContentArea() {
    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      child: _shouldShowTextArea
          ? Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _textController,
                focusNode: _textFocusNode,
                decoration: const InputDecoration(
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
    );
  }

  Widget _buildTransitionSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Transition',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            onPressed: _addSetVariable,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 24, height: 24),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSetVariables() {
    return widget.card.setVariables.asMap().entries.map((entry) {
      final i = entry.key;
      return _SetVariableWidget(
        setVariable: entry.value,
        index: i,
        cardIndex: widget.index,
        onRemove: _removeSetVariable,
        isHovered: _hoveredSetVariableIndex == i,
        onHover: (isHovered) {
          if (isHovered) {
            _hoveredSetVariableIndex = i;
          } else if (_hoveredSetVariableIndex == i) {
            _hoveredSetVariableIndex = null;
          }
          setState(() {});
        },
        onPortDragStart: widget.onPortDragStart,
        onPortDragUpdate: widget.onPortDragUpdate,
        onPortDragEnd: widget.onPortDragEnd,
        connectedPorts: widget.connectedPorts,
        portKey: widget.getPortKey?.call(widget.index, i),
        isTargeted: widget.targetedPortKey == '${widget.index}_$i',
      );
    }).toList();
  }

  Widget _buildLeftPort() {
    return Positioned(
      left: 0,
      top: 92,
      child: MouseRegion(
        cursor: SystemMouseCursors.move,
        onEnter: (_) => setState(() => _leftPortHovering = true),
        onExit: (_) => setState(() => _leftPortHovering = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) {
            _isDraggingFromPort = true;
            setState(() {});
            final portCenter = _getLeftPortCenter() ?? details.globalPosition;
            widget.onPortDragStart?.call(widget.index, PortSide.left, portCenter);
          },
          onPanUpdate: (details) => widget.onPortDragUpdate?.call(details.globalPosition),
          onPanEnd: (details) {
            _isDraggingFromPort = false;
            setState(() {});
            widget.onPortDragEnd?.call(widget.index, PortSide.left);
          },
          onPanCancel: () {
            _isDraggingFromPort = false;
            setState(() {});
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
    );
  }
}


/// SetVariable widget with port - extracted for better performance
class _SetVariableWidget extends StatefulWidget {
  final SetVariable setVariable;
  final int index;
  final int cardIndex;
  final Function(int) onRemove;
  final bool isHovered;
  final Function(bool) onHover;
  final Function(int cardIndex, PortSide side, Offset globalPosition, {int? setVarIndex})? onPortDragStart;
  final Function(Offset globalPosition)? onPortDragUpdate;
  final Function(int cardIndex, PortSide side)? onPortDragEnd;
  final Set<String>? connectedPorts;
  final GlobalKey? portKey;
  final bool isTargeted;

  const _SetVariableWidget({
    required this.setVariable,
    required this.index,
    required this.cardIndex,
    required this.onRemove,
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
  State<_SetVariableWidget> createState() => _SetVariableWidgetState();
}

class _SetVariableWidgetState extends State<_SetVariableWidget> {
  bool _portHovering = false;
  bool _isDraggingFromPort = false;
  
  GlobalKey get _portKey => widget.portKey ?? _internalKey;
  final GlobalKey _internalKey = GlobalKey();

  Offset? _getPortCenter() {
    final RenderBox? box = _portKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      return box.localToGlobal(Offset(box.size.width / 2, box.size.height / 2));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => widget.onHover(true),
      onExit: (_) => widget.onHover(false),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey.shade400)),
            ),
            child: Row(
              children: [
                if (widget.isHovered)
                  IconButton(
                    icon: Icon(Icons.close, size: 16, color: Colors.grey[600]),
                    onPressed: () => widget.onRemove(widget.index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(width: 20, height: 20),
                  )
                else
                  const SizedBox(width: 28),
                const SizedBox(width: 4),
                Icon(Icons.settings, size: 16, color: Colors.grey[600]),
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
          Positioned(
            right: -12,
            top: 8,
            child: MouseRegion(
              cursor: SystemMouseCursors.move,
              onEnter: (_) => setState(() => _portHovering = true),
              onExit: (_) => setState(() => _portHovering = false),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (details) {
                  _isDraggingFromPort = true;
                  setState(() {});
                  final portCenter = _getPortCenter() ?? details.globalPosition;
                  widget.onPortDragStart?.call(
                    widget.cardIndex, PortSide.right, portCenter, setVarIndex: widget.index);
                },
                onPanUpdate: (details) => widget.onPortDragUpdate?.call(details.globalPosition),
                onPanEnd: (details) {
                  _isDraggingFromPort = false;
                  setState(() {});
                  widget.onPortDragEnd?.call(widget.cardIndex, PortSide.right);
                },
                onPanCancel: () {
                  _isDraggingFromPort = false;
                  setState(() {});
                  widget.onPortDragEnd?.call(widget.cardIndex, PortSide.right);
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
