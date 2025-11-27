// lib/node/widgets/post_call_data_extraction_content.dart
import 'package:flutter/material.dart';

import '../models/global_settings.dart';

// Define data types
enum FieldDataType { text, boolean, number, selector }

String fieldTypeToString(FieldDataType type) {
  switch (type) {
    case FieldDataType.text: return 'text';
    case FieldDataType.boolean: return 'boolean';
    case FieldDataType.number: return 'number';
    case FieldDataType.selector: return 'selector';
  }
}

FieldDataType stringToFieldType(String type) {
  switch (type) {
    case 'text': return FieldDataType.text;
    case 'boolean': return FieldDataType.boolean;
    case 'number': return FieldDataType.number;
    case 'selector': return FieldDataType.selector;
    default: return FieldDataType.text;
  }
}

extension FieldDataTypeExt on FieldDataType {
  String get label {
    switch (this) {
      case FieldDataType.text: return 'Text';
      case FieldDataType.boolean: return 'Boolean';
      case FieldDataType.number: return 'Number';
      case FieldDataType.selector: return 'Selector';
    }
  }

  IconData get icon {
    switch (this) {
      case FieldDataType.text: return Icons.text_fields;
      case FieldDataType.boolean: return Icons.toggle_on;
      case FieldDataType.number: return Icons.numbers;
      case FieldDataType.selector: return Icons.view_list;
    }
  }
}

class PostCallField {
  final String name;
  final FieldDataType type;
  final bool isDeletable;

  PostCallField({required this.name, required this.type,    this.isDeletable = true,});
}

class PostCallDataExtractionContent extends StatefulWidget {
  // const PostCallDataExtractionContent({super.key});

  final GlobalSettings settings;
  final VoidCallback? onSettingsChanged;

  const PostCallDataExtractionContent({
    super.key,
    required this.settings,
    this.onSettingsChanged,
  });


  @override
  State<PostCallDataExtractionContent> createState() =>
      _PostCallDataExtractionContentState();
}

class _PostCallDataExtractionContentState
    extends State<PostCallDataExtractionContent> {
  // Default fields
  List<PostCallField> _fields = [];

  // List<PostCallField> _fields = [
  //   PostCallField(name: 'Call Successful', type: FieldDataType.boolean, isDeletable: false),
  //   PostCallField(name: 'Call Summary', type: FieldDataType.text, isDeletable: false),
  // ];

  @override
  void initState() {
    super.initState();
    _fields = widget.settings.postCallFields.map((jsonField) {
      return PostCallField(
        name: jsonField['name'] as String,
        type: stringToFieldType(jsonField['type'] as String),
        isDeletable: jsonField['isDeletable'] as bool? ?? true,
      );
    }).toList();
  }

  void _updateSettings() {
    widget.settings.postCallFields = _fields.map((field) {
      return {
        'name': field.name,
        'type': fieldTypeToString(field.type),
        'isDeletable': field.isDeletable,
      };
    }).toList();
    widget.onSettingsChanged?.call();
  }

  final GlobalKey _addButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Post Call Data Retrieval',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const Text(
          'Define the information that you need to extract from the voice. (Learn more)',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // Field list
        for (var i = 0; i < _fields.length; i++)
          _buildFieldItem(_fields[i], i),

        const SizedBox(height: 12),

        // Add button
        TextButton.icon(
          key: _addButtonKey, // 👈 Attach key
          onPressed: () async {
            final selected = await _showAddFieldMenu(context);
            if (selected != null) {
              setState(() {
                _fields.add(PostCallField(
                  name: 'New ${selected.label}',
                  type: selected,
                  isDeletable: true, // 👈 New fields are deletable
                ));
                _updateSettings(); // ✅ ADD THIS

              });
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Add'),
        ),
      ],
    );
  }
  Widget _buildFieldItem(PostCallField field, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(field.type.icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              field.name,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Edit ${field.name}')),
              );
            },
          ),
          // 👇 Only show delete icon if deletable
          if (field.isDeletable)
            IconButton(
              icon: const Icon(Icons.delete, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                setState(() {
                  _fields.removeAt(index);
                  _updateSettings();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Field deleted')),
                );
              },
            ),
        ],
      ),
    );
  }
  Future<FieldDataType?> _showAddFieldMenu(BuildContext context) async {
    final RenderBox? button = _addButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (button == null) return null;

    final buttonRect = button.localToGlobal(Offset.zero) & button.size;
    final position = RelativeRect.fromRect(
      buttonRect,
      Offset.zero & MediaQuery.of(context).size,
    );

    return await showMenu<FieldDataType>(
      context: context,
      position: position,
      items: FieldDataType.values
          .map((type) => PopupMenuItem(
        value: type,
        child: Row(
          children: [
            Icon(type.icon, size: 18),
            const SizedBox(width: 12),
            Text(type.label),
          ],
        ),
      ))
          .toList(),
      elevation: 4,
    );
  }
}