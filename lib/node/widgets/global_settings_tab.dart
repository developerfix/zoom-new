// lib/node/widgets/global_settings_tab.dart
import 'package:flutter/material.dart';
import 'package:zoom/node/widgets/post_call_data_extraction_content.dart';
import 'package:zoom/node/widgets/security_fallback_settings_content.dart';
import 'package:zoom/node/widgets/speech_settings_content.dart';
import 'package:zoom/node/widgets/transcription_settings_content.dart';
import 'package:zoom/node/widgets/webhook_settings_content.dart';

import '../models/global_settings.dart';
import 'agent_settings_content.dart';
import 'call_settings_content.dart';
import 'knowledge_base_content.dart';

class GlobalSettingsTab extends StatefulWidget {
  final GlobalSettings globalSettings; // 👈 ADD
  // final VoidCallback onSettingsChanged; // 👈 ADD
  final VoidCallback? onSettingsChanged; // 👈 nullable


  const GlobalSettingsTab({
    super.key,
    required this.globalSettings,
    this.onSettingsChanged, // 👈 no `required`

    // required this.onSettingsChanged,
  });
  // const GlobalSettingsTab({super.key});

  @override
  State<GlobalSettingsTab> createState() => _GlobalSettingsTabState();
}

class _GlobalSettingsTabState extends State<GlobalSettingsTab> {
  Map<String, bool> _expanded = {
    'agent': true,
    'knowledge': false,
    'speech': false,
    'transcription': false,
    'call': false,
    'postcall': false,
    'security': false,
    'transcription': false,
    'webhook': false,
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Agent Setting
          _buildSection(
            title: 'Agent setting',
            icon: Icons.settings,
            key: 'agent',
            content: AgentSettingsContent(
              settings: widget.globalSettings,
              onSettingsChanged: widget.onSettingsChanged,
            ),
            // content: AgentSettingsContent(),
          ),

          // Knowledge Base
          // _buildSection(
          //   title: 'Knowledge base',
          //   icon: Icons.book,
          //   key: 'knowledge',
          //   content: const KnowledgeBaseContent(),
          // ),
          _buildSection(
            title: 'Knowledge base',
            icon: Icons.book,
            key: 'knowledge',
            content: KnowledgeBaseContent(
              settings: widget.globalSettings,
              onSettingsChanged: widget.onSettingsChanged,
            ),
          ),



          // Speech Setting
          // _buildSection(
          //   title: 'Speech setting',
          //   icon: Icons.mic,
          //   key: 'speech',
          //   content: const SpeechSettingsContent(),
          // ),

          _buildSection(
            title: 'Speech setting',
            icon: Icons.mic,
            key: 'speech',
            content: SpeechSettingsContent(
              settings: widget.globalSettings,
              onSettingsChanged: widget.onSettingsChanged,
            ),
          ),

          // _buildSection(
          //   title: 'Call Settings',
          //   icon: Icons.phone,
          //   key: 'call',
          //   content:  SpeechSettingsContent(
          //     settings: widget.globalSettings,
          //     onSettingsChanged: widget.onSettingsChanged,
          //   ),
          // ),
          // _buildSection(
          //   title: 'Post-Call Data Extraction',
          //   icon: Icons.data_exploration,
          //   key: 'postcall',
          //   content: const PostCallDataExtractionContent(),
          // ),

          _buildSection(
            title: 'Call Settings',
            icon: Icons.phone,
            key: 'call',
            content: CallSettingsContent(
              settings: widget.globalSettings,
              onSettingsChanged: widget.onSettingsChanged,
            ),
          ),
          _buildSection(
            title: 'Post-Call Data Extraction',
            icon: Icons.data_exploration,
            key: 'postcall',
            content: PostCallDataExtractionContent(
              settings: widget.globalSettings,
              onSettingsChanged: widget.onSettingsChanged,
            ),
          ),

          _buildSection(
            title: 'Security & Fallback Settings',
            icon: Icons.security,
            key: 'security',
            content: SecurityFallbackSettingsContent(
              settings: widget.globalSettings,
              onSettingsChanged: widget.onSettingsChanged,
            ),
            // content: const SecurityFallbackSettingsContent(),
          ),
          _buildSection(
            title: 'Transcription Settings',
            icon: Icons.transcribe,
            key: 'transcription',
            content: TranscriptionSettingsContent(
              settings: widget.globalSettings,
              onSettingsChanged: widget.onSettingsChanged,
            ),
            // content: const TranscriptionSettingsContent(),
          ),
          _buildSection(
            title: 'Webhook Settings',
            icon: Icons.webhook,
            key: 'webhook',
            content: WebhookSettingsContent(
              settings: widget.globalSettings,
              onSettingsChanged: widget.onSettingsChanged,
            ),
            // content: const WebhookSettingsContent(),
          ),
          SizedBox(height: 100,)


        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required String key,
    required Widget content,
  }) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, size: 20),
            title: Text(title),
            trailing: Icon(
              _expanded[key]! ? Icons.expand_less : Icons.expand_more,
              size: 20,
            ),
            onTap: () {
              setState(() {
                _expanded[key] = !_expanded[key]!;
              });
            },
          ),
          if (_expanded[key]!)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: content,
            ),
        ],
      ),
    );
  }
}
