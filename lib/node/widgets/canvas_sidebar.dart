import 'package:flutter/material.dart';

import '../constants/node_types.dart';

class CanvasSidebar extends StatelessWidget {
  final int cardCount; // Receive the count of cards
  final Function(String title, IconData icon) onAddCard; // 👈 ADD THIS
  final VoidCallback onToggleMagicBuilder;

  CanvasSidebar({
    Key? key,
    this.cardCount = 0,
    required this.onToggleMagicBuilder,
    required this.onAddCard, // 👈

  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200, // Adjust width as needed
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...NodeTypes.all.map((node) =>
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: _buildTextMenuButton(node['name'] as String, node['icon'] as IconData),
              ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Canvas Stats',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.grid_view,
                                size: 16,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Cards: $cardCount',
                                  style:  TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Magic Builder button
                        ElevatedButton.icon(
                          onPressed: onToggleMagicBuilder, // 👈 NOW CONNECTED
                          icon: const Icon(
                            Icons.auto_fix_high,
                            size: 16,
                            color: Colors.purple,
                          ),
                          label: const Text(
                            'Magic Builder',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.purple,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade50,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                              side: BorderSide(color: Colors.purple.shade200),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _nodeTypes => NodeTypes.all;

  Widget _buildTextMenuButton(String label, IconData icon) {
    return TextButton(
      onPressed: () {
        onAddCard(label, icon);
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        alignment: Alignment.centerLeft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        foregroundColor: Colors.blue.shade700,
        splashFactory: NoSplash.splashFactory,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }}