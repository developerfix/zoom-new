
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart'; // Add this import

class TwoFingerZoomHandler {
  final Map<int, Offset> touchPositions = {};
  double initialScale = 1.0;
  double lastDistance = 0.0;

  // For smooth animation
  AnimationController? _animationController;
  double _targetScale = 1.0;
  double _currentAnimatingScale = 1.0;

  final ValueChanged<double>? onScaleChanged;
  final ValueChanged<String>? onStatusChanged;
  final VoidCallback? onScaleUpdate;
  final double minScale;
  final double maxScale;

  TwoFingerZoomHandler({
    this.onScaleChanged,
    this.onStatusChanged,
    this.onScaleUpdate,
    this.minScale = 0.1,
    this.maxScale = 5.0,
  });

  void initializeAnimation(TickerProvider vsync) {
    _animationController = AnimationController(vsync: vsync);
    _animationController!.addListener(() {
      _currentAnimatingScale = _animationController!.value;
      onScaleUpdate?.call();
    });
  }

  void handlePointerDown(PointerDownEvent event) {
    // Cancel any ongoing animation when user starts touching
    _animationController?.stop(canceled: true);

    touchPositions[event.pointer] = event.position;

    if (touchPositions.length == 2) {
      lastDistance = _calculateDistance();
      _targetScale = _currentAnimatingScale;
      onStatusChanged?.call('Two fingers detected - starting zoom mode');
    }
  }

  void handlePointerMove(PointerMoveEvent event, double currentScale) {
    touchPositions[event.pointer] = event.position;

    if (touchPositions.length == 2) {
      double currentDistance = _calculateDistance();
      double scaleChange = currentDistance / lastDistance;
      double newScale = (currentScale * scaleChange).clamp(minScale, maxScale);

      if (newScale != currentScale) {
        _currentAnimatingScale = newScale;
        onScaleChanged?.call(newScale);
        onStatusChanged?.call('Two-Finger Zoom: ${newScale.toStringAsFixed(2)}x');
      }
    }
  }

  void handlePointerUp(PointerUpEvent event) {
    touchPositions.remove(event.pointer);

    if (touchPositions.isEmpty) {
      // Start spring animation to settle the scale
      _startSpringAnimation(_currentAnimatingScale);
    }
  }

  void handlePointerCancel(PointerCancelEvent event) {
    touchPositions.remove(event.pointer);

    if (touchPositions.isEmpty) {
      _startSpringAnimation(_currentAnimatingScale);
    }
  }

  void _startSpringAnimation(double fromScale) {
    if (_animationController == null) return;

    final spring = SpringDescription(
      mass: 1.0,
      stiffness: 500.0,      // Lower = bouncier, Higher = stiffer
      damping: 18.0,         // Controls how quickly it settles
    );

    final simulation = SpringSimulation(spring, fromScale, _targetScale, 0.0)
      ..tolerance = Tolerance(distance: 0.01, velocity: 0.01);

    _animationController!.animateWith(simulation);
  }

  double _calculateDistance() {
    if (touchPositions.length < 2) return 0.0;

    List<Offset> positions = touchPositions.values.toList();
    Offset pos1 = positions[0];
    Offset pos2 = positions[1];

    return (pos1 - pos2).distance;
  }

  int get fingerCount => touchPositions.length;
  double get currentScale => _currentAnimatingScale;

  void dispose() {
    _animationController?.dispose();
  }
}