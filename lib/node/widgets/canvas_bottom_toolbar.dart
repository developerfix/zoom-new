
import 'package:flutter/material.dart';

import '../constants/node_types.dart';

class CanvasBottomToolbar extends StatefulWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onResetView;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onLockToggle;
  final bool isCanvasLocked;
  // final VoidCallback onAddCard;
  // final VoidCallback onUndo;
  // final VoidCallback onRedo;
  final Function(String title, IconData icon) onAddCardWithType; // 👈 NEW

  // Define card types directly or pass them in

  const CanvasBottomToolbar({
    Key? key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onResetView,
    // required this.onAddCard,
    required this.onUndo,
    required this.onRedo,
    // this.onUndo,        // 👈 NOT required
    // this.onRedo,        // 👈 NOT required
    required this.onAddCardWithType, // 👈
    this.onLockToggle,
    this.isCanvasLocked = false,
  }) : super(key: key);

  @override
  State<CanvasBottomToolbar> createState() => _CanvasBottomToolbarState();
}

class _CanvasBottomToolbarState extends State<CanvasBottomToolbar> {
  bool _isCanvasLocked = false;
  final GlobalKey _addButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Undo
          IconButton(
            onPressed: widget.onUndo,
            icon: const Icon(Icons.undo, size: 20),
            tooltip: 'Undo',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              foregroundColor: Colors.grey.shade800,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Redo
          IconButton(
            onPressed: widget.onRedo,
            icon: const Icon(Icons.redo, size: 20),
            tooltip: 'Redo',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              foregroundColor: Colors.grey.shade800,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Divider
          Container(
            width: 1,
            height: 24,
            color: Colors.grey.shade300,
          ),
          const SizedBox(width: 8),
          IconButton(
            key: _addButtonKey, // 👈 add this
            onPressed: () async {
              final selectedItem = await _showCardSelectionMenu(context);
              if (selectedItem != null) {
                widget.onAddCardWithType(selectedItem['name'], selectedItem['icon']);
              }
            },
            icon: const Icon(Icons.add, size: 20),
            tooltip: 'Add Card',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            style: IconButton.styleFrom(
              backgroundColor: Colors.blue.shade100,
              foregroundColor: Colors.blue.shade800,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Zoom Out
          IconButton(
            onPressed: widget.onZoomOut,
            icon: const Icon(Icons.zoom_out_map, size: 20),
            tooltip: 'Zoom Out',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              foregroundColor: Colors.grey.shade800,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Zoom In
          IconButton(
            onPressed: widget.onZoomIn,
            icon: const Icon(Icons.zoom_in_map, size: 20),
            tooltip: 'Zoom In',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              foregroundColor: Colors.grey.shade800,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Reset View
          IconButton(
            onPressed: widget.onResetView,
            icon: const Icon(Icons.fit_screen, size: 20),
            tooltip: 'Reset View',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              foregroundColor: Colors.grey.shade800,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Divider
          Container(
            width: 1,
            height: 24,
            color: Colors.grey.shade300,
          ),
          const SizedBox(width: 8),
// Replace your existing lock button with this mouse/cursor button:
          if (widget.onLockToggle != null)
            IconButton(
              onPressed: widget.onLockToggle,
              icon: Icon(
                widget.isCanvasLocked ? Icons.mouse : Icons.pan_tool,
                size: 20,
                color: widget.isCanvasLocked ? Colors.blue : Colors.grey,
              ),
              tooltip: widget.isCanvasLocked
                  ? 'Enable Canvas Interaction'
                  : 'Disable Canvas Interaction',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              style: IconButton.styleFrom(
                backgroundColor: widget.isCanvasLocked
                    ? Colors.blue.shade50
                    : Colors.grey.shade100,
                foregroundColor: widget.isCanvasLocked
                    ? Colors.blue.shade800
                    : Colors.grey.shade800,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
//           IconButton(
//             onPressed: () {
//               setState(() {
//                 _isCanvasLocked = !_isCanvasLocked;
//               });
//             },
//             icon: Icon(
//               _isCanvasLocked ? Icons.mouse : Icons.pan_tool, // Using mouse and pan_tool icons
//               size: 20,
//               color: _isCanvasLocked ? Colors.blue : Colors.grey,
//             ),
//             tooltip: _isCanvasLocked ? 'Enable Canvas Interaction' : 'Disable Canvas Interaction', // Updated tooltip
//             padding: const EdgeInsets.all(8),
//             constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
//             style: IconButton.styleFrom(
//               backgroundColor: _isCanvasLocked
//                   ? Colors.blue.shade50  // Changed to blue theme
//                   : Colors.grey.shade100,
//               foregroundColor: _isCanvasLocked
//                   ? Colors.blue.shade800  // Changed to blue theme
//                   : Colors.grey.shade800,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//           ),
        ],
      ),
    );
  }
  Future<Map<String, dynamic>?> _showCardSelectionMenu(BuildContext context) async {
    final RenderBox? button = _addButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (button == null) return null;

    final Offset localOffset = button.size.center(Offset.zero);
    final Offset globalOffset = button.localToGlobal(localOffset);

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromCircle(center: globalOffset, radius: 0),
      Offset.zero & MediaQuery.of(context).size,
    );

    return await showMenu<Map<String, dynamic>>(
      context: context,
      position: position,
      items: NodeTypes.all.map((item) { // ✅ Use shared list
        return PopupMenuItem<Map<String, dynamic>>(
          value: item,
          child: Row(
            children: [
              Icon(item['icon'] as IconData, size: 18),
              const SizedBox(width: 12),
              Text(item['name'] as String, style: const TextStyle(fontSize: 13)),
            ],
          ),
        );
      }).toList(),
      elevation: 4,
    );
  }
}