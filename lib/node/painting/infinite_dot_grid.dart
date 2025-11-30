import 'package:flutter/material.dart';

/// High-performance infinite dot grid using RepaintBoundary and cached Paint objects.
/// Optimized for smooth panning and zooming like Figma/n8n.
class InfiniteDotGrid extends StatelessWidget {
  final double scale;
  final Offset offset;
  final Color color;
  final double dotSize;
  final double baseSpacing;

  const InfiniteDotGrid({
    Key? key,
    required this.scale,
    required this.offset,
    this.color = const Color(0xFFBDBDBD), // More visible grey
    this.dotSize = 2.0,
    this.baseSpacing = 30.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _InfiniteDotGridPainter(
            spacing: baseSpacing * scale,
            dotSize: (dotSize * scale).clamp(0.8, 5.0),
            color: color,
            offset: offset,
          ),
          isComplex: true,
          willChange: true,
        ),
      ),
    );
  }
}

class _InfiniteDotGridPainter extends CustomPainter {
  final double spacing;
  final double dotSize;
  final Color color;
  final Offset offset;
  
  // Cached paint object
  late final Paint _dotPaint;

  _InfiniteDotGridPainter({
    required this.spacing,
    required this.dotSize,
    required this.color,
    required this.offset,
  }) {
    _dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Skip painting if dots would be too dense
    if (spacing < 5.0) return;
    
    // Calculate grid offset for infinite looping effect
    final double offsetX = offset.dx % spacing;
    final double offsetY = offset.dy % spacing;

    // Calculate visible range
    final int endX = (size.width / spacing).ceil() + 2;
    final int endY = (size.height / spacing).ceil() + 2;

    // Draw all dots
    for (int i = -1; i <= endX; i++) {
      final double x = offsetX + i * spacing;
      for (int j = -1; j <= endY; j++) {
        final double y = offsetY + j * spacing;
        canvas.drawCircle(Offset(x, y), dotSize, _dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_InfiniteDotGridPainter oldDelegate) {
    return oldDelegate.spacing != spacing ||
           oldDelegate.offset != offset ||
           oldDelegate.color != color ||
           oldDelegate.dotSize != dotSize;
  }
}
