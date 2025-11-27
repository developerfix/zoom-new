import 'package:flutter/material.dart';
import 'package:zoom/node/widgets/test_agent_tab.dart';
import '../models/draggable_card.dart';
import '../models/global_settings.dart';
import 'node_settings_tab.dart';
import 'global_settings_tab.dart';
import 'package:flutter/material.dart';

class RightPanel extends StatefulWidget {

  final GlobalSettings globalSettings;
  final VoidCallback? onGlobalSettingsChanged;

  final VoidCallback onClose;
  final DraggableCard? selectedCard;
  final VoidCallback? onNodeSettingsChanged;
  final VoidCallback? onTestAgentRequested;

  // const RightPanel({super.key, required this.onClose});
  const RightPanel({
    super.key,
    required this.onClose,
    this.onGlobalSettingsChanged,
    required this.globalSettings,
    this.onTestAgentRequested,
    this.selectedCard,
    this.onNodeSettingsChanged,
  });

  @override
  State<RightPanel> createState() => RightPanelState();
}

class RightPanelState extends State<RightPanel> {
  int _currentIndex = 1;
  final List<String> _tabTitles = ['Node Setting', 'Global Setting'];
  double _dragDelta = 0.0;
  bool _isDraggingFromEdge = false;

  // 👇 NEW: Allow external request to show Test Agent
  void showTestAgentTab() {
    setState(() {
      _currentIndex = 2;
    });
  }

  // @override
  // void didUpdateWidget(covariant RightPanel oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //
  //   // Only auto-switch if we are NOT on Test Agent tab
  //   if (_currentIndex != 2) {
  //     // Case 1: A card was just selected → go to Node tab
  //     if (widget.selectedCard != null && oldWidget.selectedCard != widget.selectedCard) {
  //       setState(() {
  //         _currentIndex = 0;
  //       });
  //     }
  //     // Case 2: Card was deselected (selectedCard changed from non-null to null)
  //     else if (widget.selectedCard == null && oldWidget.selectedCard != null) {
  //       setState(() {
  //         _currentIndex = 1;
  //       });
  //     }
  //     // Do NOT switch if user manually changed tab and selectedCard hasn't changed
  //   }
  // }

  @override
  void didUpdateWidget(covariant RightPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Detect if a NEW card was selected (including from Test Agent tab)
    if (widget.selectedCard != null && oldWidget.selectedCard != widget.selectedCard) {
      setState(() {
        _currentIndex = 0; // Always go to Node Setting when a card is selected
      });
    }
    // Optional: When card is deselected AND you're not on Test Agent, go to Global
    else if (widget.selectedCard == null &&
        oldWidget.selectedCard != null &&
        _currentIndex != 2) {
      setState(() {
        _currentIndex = 1;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (DragStartDetails details) {
        if (details.localPosition.dx <= 24) {
          _isDraggingFromEdge = true;
          _dragDelta = 0;
        }
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        if (_isDraggingFromEdge) {
          _dragDelta += details.primaryDelta ?? 0.0;
        }
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        if (_isDraggingFromEdge) {
          if (_dragDelta < -60 || details.velocity.pixelsPerSecond.dx < -200) {
            widget.onClose();
          }
          _isDraggingFromEdge = false;
        }
      },
      child: Container(
        width: 360,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: const Offset(-2, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 56,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  for (int i = 0; i < _tabTitles.length; i++)
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _currentIndex = i;
                          });
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: _currentIndex == i
                              ? Theme.of(context).primaryColor.withOpacity(0.1)
                              : Colors.transparent,
                          foregroundColor: _currentIndex == i
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).textTheme.bodyMedium?.color,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        ),
                        child: Text(
                          _tabTitles[i],
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child:IndexedStack(
                index: _currentIndex,
                children: [
                  NodeSettingsTab(
                    key: ValueKey(widget.selectedCard?.hashCode ?? 'none'),
                    selectedCard: widget.selectedCard,
                    onTitleChanged: widget.onNodeSettingsChanged,
                  ),
                  // const GlobalSettingsTab(),
                  GlobalSettingsTab(
                    globalSettings: widget.globalSettings,
                    onSettingsChanged: widget.onGlobalSettingsChanged,
                  ),

                  const TestAgentTab(), // 👈 NEW

                ],
              ),

            ),
          ],
        ),
      ),
    );
  }
}