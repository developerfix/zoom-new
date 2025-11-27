import 'package:flutter/material.dart';

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
    this.color = Colors.grey,
    this.dotSize = 3.0,
    this.baseSpacing = 30.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate scaled dot size (proportional to zoom level)
    final scaledDotSize = dotSize * scale;

    return CustomPaint(
      painter: InfiniteDotGridPainter(
        spacing: baseSpacing * scale,
        dotSize: scaledDotSize,
        color: color,
        offset: offset,
        scale: scale,
      ),
      child: Container(),
    );
  }
}

class InfiniteDotGridPainter extends CustomPainter {
  final double spacing;
  final double dotSize;
  final Color color;
  final Offset offset;
  final double scale;

  InfiniteDotGridPainter({
    required this.spacing,
    required this.dotSize,  // This is now the scaled size
    required this.color,
    required this.offset,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Calculate the grid offset modulo spacing for infinite looping
    // This creates the illusion of infinite scrolling
    final double offsetX = offset.dx % spacing;
    final double offsetY = offset.dy % spacing;

    // Calculate how many dots we need to draw to cover the screen
    final int dotsX = (size.width / spacing).ceil() + 2;
    final int dotsY = (size.height / spacing).ceil() + 2;

    // Draw dots in grid pattern
    // Start from -1 to ensure coverage when scrolling
    for (int i = -1; i < dotsX; i++) {
      for (int j = -1; j < dotsY; j++) {
        final x = offsetX + i * spacing;
        final y = offsetY + j * spacing;

        // Only draw dots that are visible on screen
        if (x >= -spacing && x <= size.width + spacing &&
            y >= -spacing && y <= size.height + spacing) {
          canvas.drawCircle(
            Offset(x, y),
            dotSize,  // Use the scaled dot size
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(InfiniteDotGridPainter oldDelegate) {
    return oldDelegate.spacing != spacing ||
        oldDelegate.offset != offset ||
        oldDelegate.scale != scale ||
        oldDelegate.color != color ||
        oldDelegate.dotSize != dotSize;
  }
}
