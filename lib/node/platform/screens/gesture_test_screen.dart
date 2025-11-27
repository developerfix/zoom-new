// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
//
// import '../../gestures/two_finger_zoom_handler.dart';
// import '../../models/draggable_card.dart';
// import '../../painting/infinite_dot_grid.dart';
// import '../../widgets/draggable_card_widget.dart';
//
// class GestureTestScreen extends StatefulWidget {
//   const GestureTestScreen({Key? key}) : super(key: key);
//
//   @override
//   State<GestureTestScreen> createState() => _GestureTestScreenState();
// }
//
// class _GestureTestScreenState extends State<GestureTestScreen> {
//   double _currentScale = 1.0;
//   Offset _offset = Offset.zero;
//   String _status = 'Ready to test gestures';
//
//   // Scale gesture state
//   Offset _startFocalPoint = Offset.zero;
//   Offset _startOffset = Offset.zero;
//   double _startScale = 1.0;
//
//   // Two-finger zoom handler
//   late TwoFingerZoomHandler _twoFingerZoomHandler;
//
//   // Draggable cards
//   List<DraggableCard> _cards = [
//     DraggableCard(
//       position: Offset(100, 100),
//       title: 'Card 1',
//       // color: Colors.blue[200]!,
//       zIndex: 0,
//     ),
//     DraggableCard(
//       position: Offset(300, 200),
//       title: 'Card 2',
//       // color: Colors.green[200]!,
//       zIndex: 1,
//     ),
//     DraggableCard(
//       position: Offset(500, 400),
//       title: 'Card 3',
//       // color: Colors.purple[200]!,
//       zIndex: 2,
//     ),
//   ];
//
//   // Currently dragged card index
//   int? _draggedCardIndex;
//   int? _hoveredCardIndex;
//
//   // Constants
//   static const double minScale = 0.1;
//   static const double maxScale = 5.0;
//   static const double zoomStep = 0.2;
//
//   @override
//   void initState() {
//     super.initState();
//     _twoFingerZoomHandler = TwoFingerZoomHandler(
//       onScaleChanged: _updateScale,
//       onStatusChanged: _updateStatus,
//       minScale: minScale,
//       maxScale: maxScale,
//     );
//   }
//
//   void _updateScale(double newScale) {
//     setState(() {
//       _currentScale = newScale;
//     });
//   }
//
//   void _updateStatus(String newStatus) {
//     setState(() {
//       _status = newStatus;
//     });
//   }
//
//   void _zoomIn() {
//     setState(() {
//       _currentScale = (_currentScale + zoomStep).clamp(minScale, maxScale);
//     });
//   }
//
//   void _zoomOut() {
//     setState(() {
//       _currentScale = (_currentScale - zoomStep).clamp(minScale, maxScale);
//     });
//   }
//
//   // Add a new card to the canvas
//   void _addCard() {
//     setState(() {
//       _cards.add(
//         DraggableCard(
//           position: Offset(100 + (_cards.length * 50), 100 + (_cards.length * 50)),
//           title: 'Card ${_cards.length + 1}',
//           // color: Colors.primaries[_cards.length % Colors.primaries.length].withOpacity(0.8),
//           zIndex: _cards.length, // Set z-index to current length
//         ),
//       );
//     });
//   }
//
//   // Bring a card to the front (highest z-index)
//   void _bringToFront(int index) {
//     if (index >= 0 && index < _cards.length) {
//       int maxZIndex = 0;
//       if (_cards.isNotEmpty) {
//         maxZIndex = _cards.map((card) => card.zIndex).reduce((a, b) => a > b ? a : b);
//       }
//       setState(() {
//         _cards[index].zIndex = maxZIndex + 1;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Gesture Framework Test'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.add),
//             onPressed: _addCard,
//             tooltip: 'Add Card',
//           ),
//           IconButton(
//             icon: Icon(Icons.zoom_out),
//             onPressed: _zoomOut,
//             tooltip: 'Zoom Out',
//           ),
//           IconButton(
//             icon: Icon(Icons.zoom_in),
//             onPressed: _zoomIn,
//             tooltip: 'Zoom In',
//           ),
//           IconButton(
//             icon: Icon(Icons.zoom_out_map),
//             onPressed: () => setState(() {
//               _currentScale = 1.0;
//               _offset = Offset.zero;
//             }),
//             tooltip: 'Reset View',
//           ),
//         ],
//       ),
//       body: Listener(
//         onPointerDown: (PointerDownEvent event) {
//           _twoFingerZoomHandler.handlePointerDown(event);
//         },
//         onPointerMove: (PointerMoveEvent event) {
//           _twoFingerZoomHandler.handlePointerMove(event, _currentScale);
//         },
//         onPointerUp: (PointerUpEvent event) {
//           _twoFingerZoomHandler.handlePointerUp(event);
//         },
//         onPointerCancel: (PointerCancelEvent event) {
//           _twoFingerZoomHandler.handlePointerCancel(event);
//         },
//         child: InteractiveViewer(
//           scaleEnabled: true,
//           panEnabled: true,
//           minScale: minScale,
//           maxScale: maxScale,
//           onInteractionStart: (ScaleStartDetails details) {
//             _startFocalPoint = details.focalPoint;
//             _startOffset = _offset;
//             _startScale = _currentScale;
//           },
//           onInteractionUpdate: (ScaleUpdateDetails details) {
//             if (_twoFingerZoomHandler.fingerCount < 2) { // Only handle single touch/pinch gestures
//               setState(() {
//                 // Calculate new scale
//                 double newScale = (_startScale * details.scale).clamp(minScale, maxScale);
//
//                 // Calculate the focal point in the coordinate system before scaling
//                 Offset focalPointBefore = (_startFocalPoint - _startOffset) / _startScale;
//
//                 // Calculate focal point delta for panning
//                 Offset focalPointDelta = details.focalPoint - _startFocalPoint;
//
//                 Offset focalPointAfter = (details.focalPoint - (_startOffset + focalPointDelta)) / newScale;
//
//                 // Adjust offset to keep focal point stable during zoom
//                 Offset zoomAdjustment = (focalPointAfter - focalPointBefore) * newScale;
//
//                 // Apply pan and zoom
//                 _offset = _startOffset + focalPointDelta + zoomAdjustment;
//                 _currentScale = newScale;
//                 _status = 'Pinch Zooming: ${_currentScale.toStringAsFixed(2)}x';
//
//               });
//             }
//           },
//           child: Stack(
//             children: [
//               // Infinite dot grid background
//               InfiniteDotGrid(
//                 scale: _currentScale,
//                 offset: _offset,
//               ),
//               // Draggable cards - sort by z-index to control stacking order
//               ..._getSortedCards(),
//               // Status display at bottom
//               Positioned(
//                 bottom: 16,
//                 left: 16,
//                 right: 16,
//                 child: Container(
//                   padding: const EdgeInsets.all(8.0),
//                   color: Colors.white.withOpacity(0.7),
//                   child: Text(
//                     _status,
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // Helper method to get cards sorted by z-index
//   List<Widget> _getSortedCards() {
//     List<int> sortedIndices = List.generate(_cards.length, (index) => index)
//       ..sort((a, b) => _cards[a].zIndex.compareTo(_cards[b].zIndex));
//
//     return sortedIndices.map((index) {
//       DraggableCard card = _cards[index];
//
//       return Positioned(
//         left: card.position.dx * _currentScale + _offset.dx,
//         top: card.position.dy * _currentScale + _offset.dy,
//         child: Transform.scale(
//           scale: _currentScale, // This makes the card scale with the canvas
//           child: DraggableCardWidget(
//             card: card,
//             index: index,
//             currentScale: _currentScale, // Pass current scale to the card
//             onPanStart: (details) {
//               setState(() {
//                 _draggedCardIndex = index;
//               });
//               _bringToFront(index); // Bring to front when dragging starts
//             },
//             onPanUpdate: (details) {
//               if (_draggedCardIndex == index) {
//                 setState(() {
//                   double baseSensitivity = 1.0;
//                   double zoomFactor = 1.0 / _currentScale; // Inverse of scale
//                   double sensitivity = baseSensitivity;
//                   if (_currentScale < 1.0) {
//                     // Zoomed out: reduce sensitivity but not too much
//                     sensitivity = 0.3 + 0.7 * (_currentScale); // Ranges from 0.3 at 0.1x to 1.0 at 1.0x
//                   } else {
//                     // Zoomed in: can be more sensitive
//                     sensitivity = 1.0 + 0.5 * (_currentScale - 1.0); // Gradually increases beyond 1.0x
//                   }
//
//                   // Apply sensitivity to the movement
//                   Offset adjustedDelta = details.delta * sensitivity;
//                   _cards[index].position += adjustedDelta;
//                 });
//               }
//             },
//             onPanEnd: (details) {
//               setState(() {
//                 _draggedCardIndex = null;
//               });
//             },
//             onHoverEnter: () {
//               _bringToFront(index); // Bring to front when hovering
//             },
//           ),
//         ),
//       );
//     }).toList();
//   }
// }