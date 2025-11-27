import 'package:flutter/material.dart';
import '../models/connection.dart';
import '../models/draggable_card.dart';

// DEBUG MODE: Set to true to see calculated port positions as red dots
const bool DEBUG_PORT_POSITIONS = false;

// Painter for the temporary drag line - renders ON TOP of cards
class DragLinePainter extends CustomPainter {
  final Offset? dragStartPosition;
  final Offset? dragCurrentPosition;
  final Offset? nearestPortPosition;
  final double scale;

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

    // Draw the drag line
    final paint = Paint()
      ..color = isSnapping ? Colors.green.withValues(alpha: 0.8) : Colors.blue.withValues(alpha: 0.6)
      ..strokeWidth = isSnapping ? 2.5 : 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(dragStartPosition!.dx, dragStartPosition!.dy);

    // Simple bezier curve for drag line
    final midX = (dragStartPosition!.dx + targetPos.dx) / 2;
    path.lineTo(midX, dragStartPosition!.dy);
    path.lineTo(midX, targetPos.dy);
    path.lineTo(targetPos.dx, targetPos.dy);

    if (!isSnapping) {
      // Dashed line
      final dashedPath = _createDashedPath(path, 5.0, 5.0);
      canvas.drawPath(dashedPath, paint);
    } else {
      canvas.drawPath(path, paint);
    }

    // Draw indicator circle at nearest port
    if (nearestPortPosition != null) {
      final fillPaint = Paint()
        ..color = Colors.green.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(nearestPortPosition!, 20, fillPaint);

      final borderPaint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(nearestPortPosition!, 20, borderPaint);
    }
  }

  Path _createDashedPath(Path source, double dashWidth, double dashSpace) {
    final Path dest = Path();
    final pathMetrics = source.computeMetrics();
    for (final pathMetric in pathMetrics) {
      double distance = 0.0;
      bool draw = true;
      while (distance < pathMetric.length) {
        final double length = draw ? dashWidth : dashSpace;
        final double endDistance = distance + length;
        if (endDistance > pathMetric.length) {
          if (draw) {
            dest.addPath(pathMetric.extractPath(distance, pathMetric.length), Offset.zero);
          }
          break;
        }
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

// Painter for permanent connections - renders BEHIND cards
class ConnectionPainter extends CustomPainter {
  final List<Connection> connections;
  final List<DraggableCard> cards;
  final double scale;
  final Offset offset;
  final String? hoveredConnectionId;
  final Map<String, Offset>? actualPortPositions;
  final int? draggedCardIndex;
  final Offset dragOffset;

  ConnectionPainter({
    required this.connections,
    required this.cards,
    required this.scale,
    required this.offset,
    this.hoveredConnectionId,
    this.actualPortPositions,
    this.draggedCardIndex,
    this.dragOffset = Offset.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // DEBUG: Draw calculated port positions
    if (DEBUG_PORT_POSITIONS) {
      _drawDebugPortPositions(canvas);
    }

    // Draw all connections
    for (var connection in connections) {
      if (connection.fromCardIndex >= cards.length ||
          connection.toCardIndex >= cards.length) {
        continue;
      }

      final fromCard = cards[connection.fromCardIndex];
      final toCard = cards[connection.toCardIndex];

      // Calculate port positions (with port index for SetVariable ports)
      final fromPos = _getPortPosition(
        fromCard,
        connection.fromSide,
        scale,
        offset,
        portIndex: connection.fromPortIndex,
        cardIndex: connection.fromCardIndex,
      );
      final toPos = _getPortPosition(
        toCard,
        connection.toSide,
        scale,
        offset,
        portIndex: connection.toPortIndex,
        cardIndex: connection.toCardIndex,
      );

      if (fromPos == null || toPos == null) continue;

      // Determine line color and width based on hover state
      final isHovered = hoveredConnectionId == connection.id;
      final lineColor = isHovered ? Colors.blue : Colors.grey.shade700;
      final lineWidth = isHovered ? 3.0 : 2.0;

      _drawConnectionLine(canvas, fromPos, toPos, lineColor, lineWidth,
          fromSide: connection.fromSide, toSide: connection.toSide);
    }
  }

  void _drawDebugPortPositions(Canvas canvas) {
    final debugPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    // Draw dots at all calculated port positions
    for (int i = 0; i < cards.length; i++) {
      final card = cards[i];

      // Draw left port position
      final leftPos = _getPortPosition(card, PortSide.left, scale, offset, cardIndex: i);
      if (leftPos != null) {
        canvas.drawCircle(leftPos, 4, debugPaint);
      }

      // Draw right port positions for SetVariables (test first 10)
      for (int portIdx = 0; portIdx < 10; portIdx++) {
        final rightPos = _getPortPosition(card, PortSide.right, scale, offset, portIndex: portIdx, cardIndex: i);
        if (rightPos != null) {
          canvas.drawCircle(rightPos, 4, debugPaint);
        }
      }
    }
  }

  void _drawConnectionLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color,
    double width, {
    bool isDashed = false,
    PortSide? fromSide,
    PortSide? toSide,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = _createOrthogonalPath(start, end, fromSide: fromSide, toSide: toSide);

    if (isDashed) {
      final dashedPath = _createDashedPath(path, 5.0, 5.0);
      canvas.drawPath(dashedPath, paint);
    } else {
      canvas.drawPath(path, paint);
    }
  }

  // Create orthogonal (right-angle) path that routes around cards
  // fromSide and toSide tell us which direction to extend OUT from each port
  Path _createOrthogonalPath(Offset start, Offset end, {PortSide? fromSide, PortSide? toSide}) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    // Gap to extend out from port - must clear card edge completely
    final gap = 40.0 * scale;
    final clearance = 120.0 * scale;

    // Determine direction to extend from each port based on port side
    // Right port = extend RIGHT (+x), Left port = extend LEFT (-x)
    final startExtendX = (fromSide == PortSide.right)
        ? start.dx + gap  // Right port: go right
        : start.dx - gap; // Left port: go left

    final endExtendX = (toSide == PortSide.left)
        ? end.dx - gap    // Left port: come from left
        : end.dx + gap;   // Right port: come from right

    // Simple case: Right port to Left port with enough space
    if (fromSide == PortSide.right && toSide == PortSide.left && end.dx > start.dx + gap * 2) {
      // Direct route through the middle
      final midX = (start.dx + end.dx) / 2;
      path.lineTo(midX, start.dy);
      path.lineTo(midX, end.dy);
      path.lineTo(end.dx, end.dy);
    } else {
      // Need to route around - extend out first, then route vertically, then come in
      // Determine vertical routing position (above or below both ports)
      final minY = start.dy < end.dy ? start.dy : end.dy;
      final maxY = start.dy > end.dy ? start.dy : end.dy;

      double routeY;
      if (minY > clearance) {
        routeY = minY - clearance; // Route above
      } else {
        routeY = maxY + clearance; // Route below
      }

      // Draw path: start -> extend out -> vertical route -> extend in -> end
      path.lineTo(startExtendX, start.dy);
      path.lineTo(startExtendX, routeY);
      path.lineTo(endExtendX, routeY);
      path.lineTo(endExtendX, end.dy);
      path.lineTo(end.dx, end.dy);
    }

    return path;
  }

  // ignore: unused_element
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 5.0;

    final path = Path();
    path.moveTo(start.dx, start.dy);

    final distance = (end.dx - start.dx).abs();
    final controlPointOffset = distance * 0.5;

    final controlPoint1 = Offset(start.dx + controlPointOffset, start.dy);
    final controlPoint2 = Offset(end.dx - controlPointOffset, end.dy);

    path.cubicTo(
      controlPoint1.dx,
      controlPoint1.dy,
      controlPoint2.dx,
      controlPoint2.dy,
      end.dx,
      end.dy,
    );

    // Create dashed path
    final dashedPath = _createDashedPath(path, dashWidth, dashSpace);
    canvas.drawPath(dashedPath, paint);
  }

  Path _createDashedPath(Path source, double dashWidth, double dashSpace) {
    final Path dest = Path();
    final pathMetrics = source.computeMetrics();

    for (final pathMetric in pathMetrics) {
      double distance = 0.0;
      bool draw = true;

      while (distance < pathMetric.length) {
        final double length = draw ? dashWidth : dashSpace;
        final double endDistance = distance + length;

        if (endDistance > pathMetric.length) {
          if (draw) {
            dest.addPath(
              pathMetric.extractPath(distance, pathMetric.length),
              Offset.zero,
            );
          }
          break;
        }

        if (draw) {
          dest.addPath(
            pathMetric.extractPath(distance, endDistance),
            Offset.zero,
          );
        }

        distance = endDistance;
        draw = !draw;
      }
    }

    return dest;
  }
  Offset? _getPortPosition(
      DraggableCard card,
      PortSide side,
      double scale,
      Offset offset, {
        int? portIndex,
        int? cardIndex,
      })
  {
    // Pure calculation using MEASURED constants (no GlobalKeys = no lag, accurate positions)
    // Measurements from _debugMeasurePortOffsets() output
    const double leftPortX = 12.0;
    const double leftPortY = 92.0 + 12.0;

    // Right port MEASURED values:
    // Port 0: (210.00, 198.00)
    // Port 1: (210.00, 232.00)
    // Port 2: (210.00, 266.00)
    const double rightPortX = 210.0;       // Exact X position
    const double firstPortY = 198.0;       // First port Y offset
    const double portSpacing = 34.0;       // Y spacing between ports

    final cardX = card.position.dx * scale + offset.dx;
    final cardY = card.position.dy * scale + offset.dy;

    // Apply drag offset if this is the dragged card
    final additionalOffset = (cardIndex != null && cardIndex == draggedCardIndex)
        ? dragOffset
        : Offset.zero;

    double portX;
    double portY;

    if (side == PortSide.left) {
      portX = cardX + leftPortX * scale + additionalOffset.dx;
      portY = cardY + leftPortY * scale + additionalOffset.dy;
    } else {
      // Right port - use measured values
      portX = cardX + rightPortX * scale + additionalOffset.dx;
      if (portIndex != null) {
        final portYInCard = firstPortY + (portIndex * portSpacing);
        portY = cardY + portYInCard * scale + additionalOffset.dy;
      } else {
        portY = cardY + leftPortY * scale + additionalOffset.dy;
      }
    }

    return Offset(portX, portY);
  }


  @override
  bool shouldRepaint(ConnectionPainter oldDelegate) {
    if (oldDelegate.cards != cards ||
        oldDelegate.connections != connections ||
        oldDelegate.hoveredConnectionId != hoveredConnectionId ||
        oldDelegate.scale != scale ||
        oldDelegate.offset != offset ||
        oldDelegate.draggedCardIndex != draggedCardIndex ||
        oldDelegate.dragOffset != dragOffset) {
      return true;
    }

    for (int i = 0; i < cards.length; i++) {
      if (i >= oldDelegate.cards.length ||
          cards[i].position != oldDelegate.cards[i].position) {
        return true;
      }
    }
    return false;
  }

  // Hit test for connection lines (for hover detection)
  bool hitTestConnection(Offset point, Connection connection) {
    if (connection.fromCardIndex >= cards.length ||
        connection.toCardIndex >= cards.length) {
      return false;
    }

    final fromCard = cards[connection.fromCardIndex];
    final toCard = cards[connection.toCardIndex];

    final fromPos = _getPortPosition(fromCard, connection.fromSide, scale, offset,
        portIndex: connection.fromPortIndex, cardIndex: connection.fromCardIndex);
    final toPos = _getPortPosition(toCard, connection.toSide, scale, offset,
        portIndex: connection.toPortIndex, cardIndex: connection.toCardIndex);

    if (fromPos == null || toPos == null) return false;

    // Check if point is near the bezier curve
    return _isPointNearCurve(point, fromPos, toPos,
        fromSide: connection.fromSide, toSide: connection.toSide, threshold: 10.0);
  }

  bool _isPointNearCurve(Offset point, Offset start, Offset end,
      {PortSide? fromSide, PortSide? toSide, double threshold = 15.0}) {
    // Sample points along the orthogonal path
    final path = _createOrthogonalPath(start, end, fromSide: fromSide, toSide: toSide);
    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      for (double d = 0; d < metric.length; d += 5.0) {
        final tangent = metric.getTangentForOffset(d);
        if (tangent != null) {
          final distance = (point - tangent.position).distance;
          if (distance < threshold) {
            return true;
          }
        }
      }
    }
    return false;
  }

  // ignore: unused_element
  Offset _getCubicBezierPoint(Offset start, Offset end, double t) {
    final distance = (end.dx - start.dx).abs();
    final controlPointOffset = distance * 0.5;

    final controlPoint1 = Offset(start.dx + controlPointOffset, start.dy);
    final controlPoint2 = Offset(end.dx - controlPointOffset, end.dy);

    // Cubic bezier formula
    final x = (1 - t) * (1 - t) * (1 - t) * start.dx +
        3 * (1 - t) * (1 - t) * t * controlPoint1.dx +
        3 * (1 - t) * t * t * controlPoint2.dx +
        t * t * t * end.dx;

    final y = (1 - t) * (1 - t) * (1 - t) * start.dy +
        3 * (1 - t) * (1 - t) * t * controlPoint1.dy +
        3 * (1 - t) * t * t * controlPoint2.dy +
        t * t * t * end.dy;

    return Offset(x, y);
  }
}
