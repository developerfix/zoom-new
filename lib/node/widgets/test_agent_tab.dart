import 'dart:async';
import 'package:flutter/material.dart';

class TestAgentTab extends StatefulWidget {
  const TestAgentTab({super.key});

  @override
  State<TestAgentTab> createState() => _TestAgentTabState();
}

class _TestAgentTabState extends State<TestAgentTab> {
  int _currentTabIndex = 0;
  bool _isCallActive = false;
  int _callSeconds = 0;
  Timer? _callTimer;
  Timer? _messageTimer;
  List<ChatMessage> _messages = [];

  @override
  void dispose() {
    _callTimer?.cancel();
    _messageTimer?.cancel();
    super.dispose();
  }

  void _startCall() {
    setState(() {
      _isCallActive = true;
      _callSeconds = 0;
      _messages.clear();
    });

    // Timer for call duration
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callSeconds++;
      });
    });

    // Simulate messages every 3 seconds
    _messageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      final now = DateTime.now().millisecondsSinceEpoch;
      setState(() {
        _messages.add(ChatMessage(
          id: 'sent_$now',
          text: 'Speak',
          isSent: true,
          timestamp: DateTime.now(),
        ));
        _messages.add(ChatMessage(
          id: 'recv_$now',
          text: 'Hearing...',
          isSent: false,
          timestamp: DateTime.now().add(const Duration(milliseconds: 500)),
        ));
      });
    });
  }

  void _endCall() {
    _callTimer?.cancel();
    _messageTimer?.cancel();
    setState(() {
      _isCallActive = false;
      _callSeconds = 0;
    });
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(
        id: 'chat_${DateTime.now().millisecondsSinceEpoch}',
        text: text.trim(),
        isSent: true,
        timestamp: DateTime.now(),
      ));
      // Simulate reply after 1 second
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _messages.add(ChatMessage(
              id: 'reply_${DateTime.now().millisecondsSinceEpoch}',
              text: 'Received',
              isSent: false,
              timestamp: DateTime.now(),
            ));
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Bar
        Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              _buildTabButton(0, 'Call'),
              _buildTabButton(1, 'Chat'),
            ],
          ),
        ),
        // Content
        Expanded(
          child: IndexedStack(
            index: _currentTabIndex,
            children: [
              // Call Tab
              _buildCallTab(),
              // Chat Tab
              _buildChatTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _currentTabIndex == index;
    return Expanded(
      child: TextButton(
        onPressed: () {
          setState(() {
            _currentTabIndex = index;
          });
        },
        style: TextButton.styleFrom(
          backgroundColor: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent,
          foregroundColor: isSelected
              ? Theme.of(context).primaryColor
              : Theme.of(context).textTheme.bodyMedium?.color,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildCallTab() {
    return Stack(
      children: [
        if (!_isCallActive)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mic, size: 64, color: Colors.grey),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _startCall,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Start Call'),
                ),
              ],
            ),
          ),
        if (_isCallActive)
          Column(
            children: [
              // Messages area (top 80%)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return Align(
                      alignment: msg.isSent ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: msg.isSent
                              ? Theme.of(context).primaryColor.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg.text,
                          style: TextStyle(
                            color: msg.isSent
                                ? Theme.of(context).primaryColor
                                : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Bottom controls (20%)
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Row(
                  children: [
                    // Timer
                    Text(
                      '${_callSeconds ~/ 60}:${(_callSeconds % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    // End button
                    ElevatedButton(
                      onPressed: _endCall,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('End'),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildChatTab() {
    final TextEditingController _controller = TextEditingController();

    return Column(
      children: [
        // Messages area
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return Align(
                alignment: msg.isSent ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: msg.isSent
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: msg.isSent
                          ? Theme.of(context).primaryColor
                          : null,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Input area
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child:
                TextField(
                  controller: _controller,
                  minLines:3,
                  maxLines: 6,        //  Allows unlimited lines
                  keyboardType: TextInputType.multiline, // (Optional but recommended for mobile)
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  onSubmitted: (value) {
                    _sendMessage(value);
                    _controller.clear();
                  },
                ),              ),
              IconButton(
                icon: const Icon(Icons.send),
                color: Theme.of(context).primaryColor,
                onPressed: () {
                  _sendMessage(_controller.text);
                  _controller.clear();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ChatMessage {
  final String id;
  final String text;
  final bool isSent;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isSent,
    required this.timestamp,
  });
}