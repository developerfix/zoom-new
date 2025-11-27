
import 'package:flutter/material.dart';

import '../constants/node_types.dart';





// ===== SET VARIABLE MODEL (unchanged) =====
class SetVariable {
  // String name;
  // String value;
  // String id;
  // SetVariable({
  //   required this.name,
  //   required this.value,
  // }) ;
  String name;
  String value;
  String id; // 👈 remove initializer

  SetVariable({
    required this.name,
    required this.value,
    String? id, // 👈 optional id
  }) : id = id ?? UniqueKey().toString(); // 👈 assign in constructor

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'value': value,
    };
  }

  factory SetVariable.fromJson(Map<String, dynamic> json) {
    return SetVariable(
      id: json['id'] ?? UniqueKey().toString(),
      name: json['name'] ?? '',
      value: json['value'] ?? '',
    );
  }

}

// ===== CARD-SET-VARIABLE STORAGE (unchanged) =====
final Map<int, List<SetVariable>> _cardSetVariables = {};

extension SetVariableExtension on DraggableCard {
  List<SetVariable> get setVariables {
    if (!_cardSetVariables.containsKey(hashCode)) {
      _cardSetVariables[hashCode] = [];
    }
    return _cardSetVariables[hashCode]!;
  }

  void addSetVariable(String name, String value) {
    if (!_cardSetVariables.containsKey(hashCode)) {
      _cardSetVariables[hashCode] = [];
    }
    _cardSetVariables[hashCode]!.add(SetVariable(name: name, value: value));
  }

  void removeSetVariable(int index) {
    if (_cardSetVariables.containsKey(hashCode)) {
      final list = _cardSetVariables[hashCode]!;
      if (index >= 0 && index < list.length) {
        list.removeAt(index);
      }
    }
  }

  void clearSetVariables() {
    if (_cardSetVariables.containsKey(hashCode)) {
      _cardSetVariables[hashCode]!.clear();
    }
  }

  void setSetVariables(List<SetVariable> variables) {
    if (!_cardSetVariables.containsKey(hashCode)) {
      _cardSetVariables[hashCode] = [];
    }
    _cardSetVariables[hashCode]!.clear();
    _cardSetVariables[hashCode]!.addAll(variables);
  }
}

// ===== DRAGGABLE CARD MODEL (UPDATED) =====
class DraggableCard {
  Offset position;
  String title;
  int zIndex;
  bool isCollapsed;
  String textContent;
  bool isEditingTitle;
  String editedTitle;
  // Node Settings
  bool skipResponse;
  bool globalNode;
  bool blockInterruptions;
  bool useCustomLLM;
  String? iconKey; // 👈 NEW: stores icon identifier (e.g., 'phone_in_talk')
  String id = UniqueKey().toString(); // in DraggableCard constructor
  // Non-serialized UI state
  GlobalKey cardKey = GlobalKey();
  GlobalKey? leftPortKey;
  Map<int, GlobalKey> rightPortKeys = {};

  DraggableCard copy() {
    return DraggableCard(
      position: position,
      title: title,
      zIndex: zIndex,
      isCollapsed: isCollapsed,
      textContent: textContent,
      isEditingTitle: isEditingTitle,
      editedTitle: editedTitle,
      skipResponse: skipResponse,
      globalNode: globalNode,
      blockInterruptions: blockInterruptions,
      useCustomLLM: useCustomLLM,
      iconKey: iconKey,
    )..setSetVariables(List<SetVariable>.from(setVariables.map((sv) => SetVariable(name: sv.name, value: sv.value))));
  }

  DraggableCard({
    required this.position,
    required this.title,
    this.zIndex = 0,
    this.isCollapsed = false,
    this.textContent = '',
    this.isEditingTitle = false,
    String? editedTitle,
    this.skipResponse = false,
    this.globalNode = false,
    this.blockInterruptions = false,
    this.useCustomLLM = false,
    this.iconKey, // 👈
  }) : editedTitle = editedTitle ?? title;

  IconData getIconData() {
    final match = NodeTypes.all.firstWhere(
          (node) => node['key'] == iconKey,
      orElse: () => {'icon': Icons.label},
    );
    return match['icon'] as IconData;
  }

  // Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'position': {'dx': position.dx, 'dy': position.dy},
      'title': title,
      'zIndex': zIndex,
      'isCollapsed': isCollapsed,
      'textContent': textContent,
      'isEditingTitle': isEditingTitle,
      'editedTitle': editedTitle,
      'skip_response': skipResponse,
      'global_node': globalNode,
      'block_interruptions': blockInterruptions,
      'use_custom_llm': useCustomLLM,
      'iconKey': iconKey, // 👈 Save as string
      'setVariables': setVariables.map((sv) => sv.toJson()).toList(),
    };
  }

  // Deserialize from JSON
  factory DraggableCard.fromJson(Map<String, dynamic> json) {
    final card = DraggableCard(
      position: Offset(
        (json['position']['dx'] as num?)?.toDouble() ?? 0.0,
        (json['position']['dy'] as num?)?.toDouble() ?? 0.0,
      ),
      title: json['title'] ?? '',
      zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
      isCollapsed: json['isCollapsed'] ?? false,
      textContent: json['textContent'] ?? '',
      isEditingTitle: json['isEditingTitle'] ?? false,
      editedTitle: json['editedTitle'] ?? '',
      // 👇 ADD THESE LINES
      skipResponse: json['skip_response'] ?? false,
      globalNode: json['global_node'] ?? false,
      blockInterruptions: json['block_interruptions'] ?? false,
      useCustomLLM: json['use_custom_llm'] ?? false,
      // 👇
      iconKey: json['iconKey'],
    );

    if (json['setVariables'] != null) {
      final setVariables = <SetVariable>[];
      for (var svJson in json['setVariables']) {
        setVariables.add(SetVariable.fromJson(svJson));
      }
      card.setSetVariables(setVariables);
    }

    return card;
  }

  Offset? getGlobalPosition() {
    final RenderBox? renderBox = cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      return renderBox.localToGlobal(Offset.zero);
    }
    return null;
  }

  Size? getCardSize() {
    final RenderBox? renderBox = cardKey.currentContext?.findRenderObject() as RenderBox?;
    return renderBox?.size;
  }
}
