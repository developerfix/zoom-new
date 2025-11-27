import 'package:flutter/material.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  final String title;
  final VoidCallback? onPublish;
  final VoidCallback? onTestAgent;
  final VoidCallback? onExport;
  final VoidCallback? onImport;

  const TopBar({
    Key? key,
    required this.onBack,
    this.title = 'Agent Automation',
    this.onPublish,
    this.onTestAgent,
    this.onExport,
    this.onImport,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBack,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      actions: [
        if (MediaQuery.sizeOf(context).width >= 600) ...[
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: onExport ?? () {
              print('Export button pressed');
            },
            tooltip: 'Export Canvas',
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.upload),
            onPressed: onImport ?? () {
              print('Import button pressed');
            },
            tooltip: 'Import Canvas',
          ),
          const SizedBox(width: 8),
        ],
        // Test Agent button (responsive)
        if (MediaQuery.sizeOf(context).width >= 600)
          OutlinedButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Test Agent'),
            onPressed: onTestAgent ?? () {
              print('Test Agent button pressed');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              side: BorderSide(color: Theme.of(context).colorScheme.primary),
              minimumSize: const Size(88, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          )
        else
          Tooltip(
            message: 'Test Agent',
            child: OutlinedButton(
              onPressed: onTestAgent ?? () {
                print('Test Agent button pressed');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                minimumSize: const Size(40, 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.play_arrow, size: 20),
            ),
          ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.publish),
          label: const Text('Publish'),
          onPressed: onPublish ?? () {
            print('Publish button pressed');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(88, 40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(width: 16),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.0),
        child: Container(
          height: 0,
          color: Colors.transparent,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}