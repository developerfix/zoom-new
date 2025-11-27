// lib/node/widgets/knowledge_base_content.dart
import 'package:flutter/material.dart';

import '../models/global_settings.dart';

class KnowledgeBaseContent extends StatefulWidget {
  final GlobalSettings settings;
  final VoidCallback? onSettingsChanged;

  const KnowledgeBaseContent({
    super.key,
    required this.settings,
    this.onSettingsChanged,
  });
  // const KnowledgeBaseContent({super.key});

  @override
  State<KnowledgeBaseContent> createState() => _KnowledgeBaseContentState();
}

class _KnowledgeBaseContentState extends State<KnowledgeBaseContent> {
  List<String> _knowledgeItems = [];

  @override
  void initState() {
    super.initState();
    _knowledgeItems = List<String>.from(widget.settings.knowledgeBase);
  }

  @override
  void didUpdateWidget(KnowledgeBaseContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.settings != oldWidget.settings) {
      _knowledgeItems = List<String>.from(widget.settings.knowledgeBase);
    }
  }

  void _addKnowledgeItem(String item) {
    setState(() {
      _knowledgeItems.add(item);
      // 👇 Sync to global settings
      widget.settings.knowledgeBase = List<String>.from(_knowledgeItems);
      widget.onSettingsChanged?.call();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$item added')),
    );
  }
  // void _addKnowledgeItem(String item) {
  //   setState(() {
  //     _knowledgeItems.add(item);
  //   });
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(content: Text('$item added')),
  //   );
  // }

  // void _removeKnowledgeItem(int index) {
  //   setState(() {
  //     _knowledgeItems.removeAt(index);
  //   });
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text('Item removed')),
  //   );
  // }
  void _removeKnowledgeItem(int index) {
    setState(() {
      _knowledgeItems.removeAt(index);
      // 👇 Sync to global settings
      widget.settings.knowledgeBase = List<String>.from(_knowledgeItems);
      widget.onSettingsChanged?.call();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item removed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add knowledge base to provide context to the agent.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 12),

        // 👇 Updated PopupMenuButton with "Add" text
        PopupMenuButton<String>(
          // Remove `icon` and use `child` to show text + icon
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.add, size: 18),
              SizedBox(width: 6),
              Text('Add'),
            ],
          ),
          onSelected: (value) {
            if (value == 'add_new') {
              _addKnowledgeItem('New Knowledge Base');
            } else if (value == 'sms_knowledge') {
              _addKnowledgeItem('SMS Knowledge');
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'sms_knowledge',
              child: const Text('SMS Knowledge'),
            ),
            const PopupMenuItem<String>(
              enabled: false,
              child: Divider(height: 1),
            ),
            PopupMenuItem<String>(
              value: 'add_new',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Add New Knowledge Base'),
                  Icon(Icons.add_circle_outline, size: 18),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 👇 Display added items with delete icon
        if (_knowledgeItems.isNotEmpty)
          Column(
            children: [
              const Divider(height: 20),
              for (var i = 0; i < _knowledgeItems.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.book, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_knowledgeItems[i]),
                      ),
                      // 👇 Delete icon on the right
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18, color: Colors.grey),
                        onPressed: () => _removeKnowledgeItem(i),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }
}