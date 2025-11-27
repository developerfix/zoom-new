// lib/node/widgets/node_settings_tab.dart
import 'package:flutter/material.dart';

import '../models/draggable_card.dart';

class NodeSettingsTab extends StatefulWidget {

  final DraggableCard? selectedCard;
  final VoidCallback? onTitleChanged;

  // const NodeSettingsTab({super.key});
  const NodeSettingsTab({
    super.key,
    this.selectedCard,
    this.onTitleChanged,
  });

  @override
  State<NodeSettingsTab> createState() => _NodeSettingsTabState();
}

class _NodeSettingsTabState extends State<NodeSettingsTab> {
  late TextEditingController _titleController;
  late TextEditingController _promptController;

  late FocusNode _titleFocusNode;

  // Toggles
  bool _skipResponse = false;
  bool _globalNode = false;
  bool _blockInterruptions = false;
  bool _useCustomLLM = false;

  @override
  void initState() {
    super.initState();
    final card = widget.selectedCard;
    _skipResponse = card?.skipResponse ?? false;
    _globalNode = card?.globalNode ?? false;
    _blockInterruptions = card?.blockInterruptions ?? false;
    _useCustomLLM = card?.useCustomLLM ?? false;
    _titleController = TextEditingController(
      text: card?.title ?? 'Conversation Node',
    );
    _promptController = TextEditingController(
      text: card?.textContent ?? 'Hello! How can I assist you today?',
    );
    _titleFocusNode = FocusNode();
    _titleFocusNode.addListener(_onTitleFocusChange); // 👈 listen to focus
  }

  void _onTitleFocusChange() {
    if (!_titleFocusNode.hasFocus) {
      // User left the field → apply fallback if empty
      String currentText = _titleController.text.trim();
      if (currentText.isEmpty) {
        _titleController.text = 'Unnamed Node';
      }
      // Update the card (if needed, though onChanged may already do it)
      if (widget.selectedCard != null) {
        widget.selectedCard!.title = _titleController.text;
      }
      widget.onTitleChanged?.call();
    }
  }
  @override
  void didUpdateWidget(NodeSettingsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCard != oldWidget.selectedCard) {
      _titleController.text = widget.selectedCard?.title ?? 'Conversation Node';
      _promptController.text = widget.selectedCard?.textContent ?? 'Hello! How can I assist you today?';
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _titleFocusNode.removeListener(_onTitleFocusChange); // 👈
    _titleFocusNode.dispose(); // 👈
    _titleController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  void _onTitleChanged() {
    if (widget.selectedCard != null) {
      widget.selectedCard!.title = _titleController.text;
      widget.onTitleChanged?.call(); // e.g., to trigger save or re-render
    }
  }

  void _onPromptChanged() {
    if (widget.selectedCard != null) {
      widget.selectedCard!.textContent = _promptController.text;
    }
  }


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Editable Title with Icon (No Border)
          Row(
            children: [
              if (widget.selectedCard != null)
                Icon(
                  widget.selectedCard!.getIconData(),
                  size: 20,
                  color: Theme.of(context).iconTheme.color,
                )
              else
                Icon(Icons.text_snippet, size: 20),
              // Icon(Icons.text_snippet, size: 20, color: Theme.of(context).iconTheme.color),
              const SizedBox(width: 8),
              Expanded(
                child:TextField(
                  controller: _titleController,
                  focusNode: _titleFocusNode,
                  onChanged: (value) {
                    // Update the card title immediately as you type
                    if (widget.selectedCard != null) {
                      widget.selectedCard!.title = value;
                      widget.onTitleChanged?.call();
                    }
                  },
                  decoration: const InputDecoration(
                    hintText: 'Node title',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                // TextField(
                //   controller: _titleController,
                //   focusNode: _titleFocusNode,
                //   decoration: const InputDecoration(
                //     hintText: 'Node title',
                //     border: InputBorder.none, // ✅ No border
                //     contentPadding: EdgeInsets.symmetric(vertical: 8),
                //   ),
                //   style: Theme.of(context).textTheme.titleMedium?.copyWith(
                //     fontWeight: FontWeight.bold,
                //     fontSize: 16,
                //   ),
                // ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Prompt
          const Text(
            'Prompt',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          const Text(
            'Enter the prompt for this conversation node',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _promptController,
            onChanged: (value) {
              if (widget.selectedCard != null) {
                widget.selectedCard!.textContent = value;
                widget.onTitleChanged?.call(); // reuse the same callback or add a new one
              }
            },
            maxLines: 5,
            minLines: 3,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 24),

          // Skip Response
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Skip Response', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    Text(
                      'Jump to next node without waiting for user response',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // Switch(
              //   value: _skipResponse,
              //   onChanged: (value) => setState(() => _skipResponse = value),
              // ),
              Switch(
                value: _skipResponse,
                onChanged: (value) {
                  setState(() => _skipResponse = value);
                  if (widget.selectedCard != null) {
                    widget.selectedCard!.skipResponse = value;
                    widget.onTitleChanged?.call(); // 👈 triggers export/undo/save
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Global Node
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Global Node', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    Text(
                      'Allow other nodes to jump to this node without edges',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _globalNode,
                onChanged: (value) {
                  setState(() => _globalNode = value);
                  if (widget.selectedCard != null) {
                    widget.selectedCard!.globalNode = value;
                    widget.onTitleChanged?.call();
                  }
                },
                // onChanged: (value) => setState(() => _globalNode = value),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Block Interruptions
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Block Interruptions', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    Text(
                      'Users cannot interrupt while AI is speaking',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _blockInterruptions,
                onChanged: (value) {
                  setState(() => _blockInterruptions = value);
                  if (widget.selectedCard != null) {
                    widget.selectedCard!.blockInterruptions = value;
                    widget.onTitleChanged?.call();
                  }
                },
                // onChanged: (value) => setState(() => _blockInterruptions = value),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // LLM
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('LLM', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    Text(
                      'Choose a different LLM for this node',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _useCustomLLM,
                onChanged: (value) {
                  setState(() => _useCustomLLM = value);
                  if (widget.selectedCard != null) {
                    widget.selectedCard!.useCustomLLM = value;
                    widget.onTitleChanged?.call();
                  }
                },
                // onChanged: (value) => setState(() => _useCustomLLM = value),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Node Knowledge Base
          const Text(
            'Node Knowledge Base',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          const Text(
            'Add knowledge base to provide context to the agent.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () {
              // Handle "Add Knowledge Base"
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add knowledge base')),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
        ],
      ),
    );
  }
}