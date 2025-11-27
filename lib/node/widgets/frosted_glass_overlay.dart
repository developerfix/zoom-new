// lib/node/widgets/frosted_glass_overlay.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class FrostedGlassOverlay extends StatefulWidget {
  final bool isVisible;
  final VoidCallback? onClose;

  const FrostedGlassOverlay({
    super.key,
    required this.isVisible,
    this.onClose,
  });

  @override
  State<FrostedGlassOverlay> createState() => _FrostedGlassOverlayState();
}

class _FrostedGlassOverlayState extends State<FrostedGlassOverlay> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _messagesScrollController = ScrollController();
  final List<Map<String, String>> _messages = [];

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Add user message
    setState(() {
      _messages.add({'role': 'user', 'text': text});
    });
    _controller.clear();

    // Simulate reply after delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _messages.add({'role': 'system', 'text': 'Message received'});
        });
        // Scroll to bottom after reply
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_messagesScrollController.hasClients) {
            _messagesScrollController.animateTo(
              _messagesScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _messagesScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Positioned.fill(
      child: GestureDetector(
        onTap: widget.onClose,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Frosted glass background
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                color: Colors.white.withOpacity(0.05),
              ),
            ),

            // Messages area (scrollable)
            Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 400,
                height: 450,
                child: Padding(
                  padding: const EdgeInsets.only(top: 60, bottom: 12),
                  child: ListView.builder(
                    controller: _messagesScrollController,
                    itemCount: _messages.length,
                    reverse: false,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg['role'] == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(
                            maxWidth: 280,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 12,
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.grey[300]! : Colors.grey[200]!,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            msg['text']!,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                            ),
                            softWrap: true,
                            overflow: TextOverflow.clip,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Input field at bottom
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: 400,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          maxLines: 4, // ✅ Allow multi-line
                          minLines: 1,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Type your message...',
                            hintStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onSubmitted: (value) {
                            // Support Shift+Enter for newline, Enter to send
                            if (_controller.text.contains('\n')) {
                              // Do nothing—let user edit
                            } else {
                              _sendMessage();
                            }
                          },
                          onChanged: (_) {
                            // Auto-scroll to bottom when typing (optional)
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton(
                        mini: true,
                        backgroundColor: Colors.purple,
                        onPressed: _sendMessage,
                        child: const Icon(Icons.send, size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Close button
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: widget.onClose,
                splashRadius: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}