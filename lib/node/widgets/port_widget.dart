import 'package:flutter/material.dart';
import '../models/connection.dart';

/// Optimized port widget with cached decorations for better performance
class PortWidget extends StatelessWidget {
  final PortSide side;
  final bool isHovering;
  final bool isConnected;
  final bool isDragging;
  final bool isTargeted;

  const PortWidget({
    super.key,
    required this.side,
    this.isHovering = false,
    this.isConnected = false,
    this.isDragging = false,
    this.isTargeted = false,
  });

  // Cached decorations for performance
  static final _draggingDecoration = BoxDecoration(
    shape: BoxShape.circle,
    color: Colors.blue,
    border: Border.all(color: Colors.blue.shade700, width: 2),
    boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 4, spreadRadius: 1)],
  );

  static final _targetedDecoration = BoxDecoration(
    shape: BoxShape.circle,
    color: Colors.green.shade300,
    border: Border.all(color: Colors.green.shade700, width: 3),
    boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)],
  );

  static final _connectedDecoration = BoxDecoration(
    shape: BoxShape.circle,
    color: Colors.green,
    border: Border.all(color: Colors.green.shade700, width: 2),
  );

  static final _hoveringDecoration = BoxDecoration(
    shape: BoxShape.circle,
    color: Colors.blue.shade200,
    border: Border.all(color: Colors.grey.shade600, width: 2),
    boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 4, spreadRadius: 1)],
  );

  static final _defaultDecoration = BoxDecoration(
    shape: BoxShape.circle,
    color: Colors.grey.shade400,
    border: Border.all(color: Colors.grey.shade600, width: 2),
  );

  static const _innerDot = BoxDecoration(
    shape: BoxShape.circle,
    color: Colors.white,
  );

  BoxDecoration _getDecoration() {
    if (isDragging) return _draggingDecoration;
    if (isTargeted) return _targetedDecoration;
    if (isConnected) return _connectedDecoration;
    if (isHovering) return _hoveringDecoration;
    return _defaultDecoration;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: _getDecoration(),
      child: const Center(
        child: SizedBox(
          width: 6,
          height: 6,
          child: DecoratedBox(decoration: _innerDot),
        ),
      ),
    );
  }
}
