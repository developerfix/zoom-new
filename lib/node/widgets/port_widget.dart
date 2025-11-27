import 'package:flutter/material.dart';
import '../models/connection.dart';

class PortWidget extends StatelessWidget {
  final PortSide side;
  final bool isHovering;
  final bool isConnected;
  final bool isDragging;
  final bool isTargeted;  // True when being targeted by a connection drag

  const PortWidget({
    super.key,
    required this.side,
    this.isHovering = false,
    this.isConnected = false,
    this.isDragging = false,
    this.isTargeted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDragging
            ? Colors.blue
            : isTargeted
                ? Colors.green.shade300
                : isConnected
                    ? Colors.green
                    : isHovering
                        ? Colors.blue.shade200
                        : Colors.grey.shade400,
        border: Border.all(
          color: isDragging
              ? Colors.blue.shade700
              : isTargeted
                  ? Colors.green.shade700
                  : isConnected
                      ? Colors.green.shade700
                      : Colors.grey.shade600,
          width: isTargeted ? 3 : 2,
        ),
        boxShadow: [
          if (isHovering || isDragging || isTargeted)
            BoxShadow(
              color: isTargeted
                  ? Colors.green.withValues(alpha: 0.5)
                  : Colors.blue.withValues(alpha: 0.3),
              blurRadius: isTargeted ? 8 : 4,
              spreadRadius: isTargeted ? 2 : 1,
            ),
        ],
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
