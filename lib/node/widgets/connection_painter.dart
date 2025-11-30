import 'package:flutter/material.dart';
import '../models/connection.dart';
import '../models/draggable_card.dart';

/// High-performance connection painter with cached calculations
/// and minimal repaints for butter-smooth canvas interactions.

// Painter for the temporary drag line - renders ON TOP of cards
class DragLinePainter extends CustomPainter {
  final Offset? dragStartPosition;
  final Offset? dragCurrentPosition;
  final Offset? nearestPortPosition;
  final double scale;

  // Cached paints
  static final Paint _dragPaint = Paint()
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  
  static final Paint _snapPaint = Paint()
    ..strokeWidth = 2.5
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  
  static final Paint _snapFillPaint = Paint()
    ..style = PaintingStyle.fill;
  
  static final Paint _snapBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  DragLinePainter({
    this.dragStartPosition,
    this.dragCurrentPosition,
    this.nearestPortPosition,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dragStartPosition == null || dragCurrentPosition == null) return;

    final targetPos = nearestPortPosition ?? dragCurrentPosition!;
    final isSnapping = nearestPortPosition != null;

    final paint = isSnapping ? _snapPaint : _dragPaint;
    paint.color = isSnapping 
        ? const Color(0xCC4CAF50) 
        : const Color(0x992196F3);

    final path = Path()
      ..moveTo(dragStartPosition!.dx, dragStartPosition!.dy);

    final midX = (dragStartPosition!.dx + targetPos.dx) / 2;
    path.lineTo(midX, dragStartPosition!.dy);
    path.lineTo(midX, targetPos.dy);
    path.lineTo(targetPos.dx, targetPos.dy);

    if (!isSnapping) {
      canvas.drawPath(_createDashedPath(path, 5.0, 5.0), paint);
    } else {
      canvas.drawPath(path, paint);
    }

    if (nearestPortPosition != null) {
      _snapFillPaint.color = const Color(0x4D4CAF50);
      canvas.drawCircle(nearestPortPosition!, 20, _snapFillPaint);
      _snapBorderPaint.color = const Color(0xFF4CAF50);
      canvas.drawCircle(nearestPortPosition!, 20, _snapBorderPaint);
    }
  }

  Path _createDashedPath(Path source, double dashWidth, double dashSpace) {
    final Path dest = Path();
    for (final pathMetric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < pathMetric.length) {
        final double length = draw ? dashWidth : dashSpace;
        final double endDistance = (distance + length).clamp(0, pathMetric.length);
        if (draw) {
          dest.addPath(pathMetric.extractPath(distance, endDistance), Offset.zero);
        }
        distance = endDistance;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(DragLinePainter oldDelegate) {
    return oldDelegate.dragStartPosition != dragStartPosition ||
        oldDelegate.dragCurrentPosition != dragCurrentPosition ||
        oldDelegate.nearestPortPosition != nearestPortPosition;
  }
}

/// Part 2: ConnectionPainter - High-performance permanent connections painter

class ConnectionPainter extends CustomPainter {
  final List<Connection> connections;
  final List<DraggableCard> cards;
  final double scale;
  final Offset offset;
  final String? hoveredConnectionId;
  final int? draggedCardIndex;
  final Offset dragOffset;

  // Cached paints for performance
  static final Paint _normalPaint = Paint()
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  
  static final Paint _hoveredPaint = Paint()
    ..strokeWidth = 3.0
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  // Port position constants (measured from widget structure)
  static const double _leftPortX = 12.0;
  static const double _leftPortY = 104.0;
  static const double _rightPortX = 210.0;
  static const double _firstPortY = 198.0;
  static const double _portSpacing = 34.0;

  ConnectionPainter({
    required this.connections,
    required this.cards,
    required this.scale,
    required this.offset,
    this.hoveredConnectionId,
    Map<String, Offset>? actualPortPositions,
    this.draggedCardIndex,
    this.dragOffset = Offset.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final connection in connections) {
      if (connection.fromCardIndex >= cards.length ||
          connection.toCardIndex >= cards.length) {
        continue;
      }

      final fromPos = _getPortPosition(
        cards[connection.fromCardIndex],
        connection.fromSide,
        connection.fromPortIndex,
        connection.fromCardIndex,
      );
      final toPos = _getPortPosition(
        cards[connection.toCardIndex],
        connection.toSide,
        connection.toPortIndex,
        connection.toCardIndex,
      );

      if (fromPos == null || toPos == null) continue;

      final isHovered = hoveredConnectionId == connection.id;
      final paint = isHovered ? _hoveredPaint : _normalPaint;
      paint.color = isHovered ? const Color(0xFF2196F3) : const Color(0xFF616161);

      _drawConnection(canvas, fromPos, toPos, paint, connection.fromSide, connection.toSide);
    }
  }

  Offset? _getPortPosition(DraggableCard card, PortSide side, int? portIndex, int cardIndex) {
    final cardX = card.position.dx * scale + offset.dx;
    final cardY = card.position.dy * scale + offset.dy;
    
    final additionalOffset = (cardIndex == draggedCardIndex) ? dragOffset : Offset.zero;

    if (side == PortSide.left) {
      return Offset(
        cardX + _leftPortX * scale + additionalOffset.dx,
        cardY + _leftPortY * scale + additionalOffset.dy,
      );
    } else {
      final portY = portIndex != null 
          ? _firstPortY + (portIndex * _portSpacing)
          : _leftPortY;
      return Offset(
        cardX + _rightPortX * scale + additionalOffset.dx,
        cardY + portY * scale + additionalOffset.dy,
      );
    }
  }

  void _drawConnection(Canvas canvas, Offset start, Offset end, Paint paint, PortSide fromSide, PortSide toSide) {
    final path = Path()..moveTo(start.dx, start.dy);
    
    final gap = 40.0 * scale;
    final clearance = 120.0 * scale;

    final startExtendX = (fromSide == PortSide.right) ? start.dx + gap : start.dx - gap;
    final endExtendX = (toSide == PortSide.left) ? end.dx - gap : end.dx + gap;

    if (fromSide == PortSide.right && toSide == PortSide.left && end.dx > start.dx + gap * 2) {
      final midX = (start.dx + end.dx) / 2;
      path.lineTo(midX, start.dy);
      path.lineTo(midX, end.dy);
      path.lineTo(end.dx, end.dy);
    } else {
      final minY = start.dy < end.dy ? start.dy : end.dy;
      final maxY = start.dy > end.dy ? start.dy : end.dy;
      final routeY = minY > clearance ? minY - clearance : maxY + clearance;

      path.lineTo(startExtendX, start.dy);
      path.lineTo(startExtendX, routeY);
      path.lineTo(endExtendX, routeY);
      path.lineTo(endExtendX, end.dy);
      path.lineTo(end.dx, end.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ConnectionPainter oldDelegate) {
    // Quick reference checks first
    if (oldDelegate.hoveredConnectionId != hoveredConnectionId ||
        oldDelegate.scale != scale ||
        oldDelegate.offset != offset ||
        oldDelegate.draggedCardIndex != draggedCardIndex ||
        oldDelegate.dragOffset != dragOffset ||
        oldDelegate.connections.length != connections.length ||
        oldDelegate.cards.length != cards.length) {
      return true;
    }

    // Check card positions only if dragging
    if (draggedCardIndex != null) {
      return true;
    }

    // Deep comparison for connections
    for (int i = 0; i < connections.length; i++) {
      if (connections[i].id != oldDelegate.connections[i].id) {
        return true;
      }
    }

    // Check card positions
    for (int i = 0; i < cards.length; i++) {
      if (cards[i].position != oldDelegate.cards[i].position) {
        return true;
      }
    }

    return false;
  }
}
