// lib/node/widgets/webhook_settings_content.dart
import 'package:flutter/material.dart';

import '../models/global_settings.dart';

class WebhookSettingsContent extends StatefulWidget {
  // const WebhookSettingsContent({super.key});
  final GlobalSettings settings;
  final VoidCallback? onSettingsChanged;

  const WebhookSettingsContent({
    super.key,
    required this.settings,
    this.onSettingsChanged,
  });

  @override
  State<WebhookSettingsContent> createState() => _WebhookSettingsContentState();
}

class _WebhookSettingsContentState extends State<WebhookSettingsContent> {
  // final TextEditingController _webhookUrlController = TextEditingController();
  // double _timeoutSeconds = 5.0; // default

  late String _webhookUrl;
  late double _timeoutSeconds;
  @override
  void initState() {
    super.initState();
    final s = widget.settings;
    _webhookUrl = s.webhookUrl;
    _timeoutSeconds = s.webhookTimeout;
  }

  void _updateSettings() {
    widget.settings
      ..webhookUrl = _webhookUrl
      ..webhookTimeout = _timeoutSeconds;
    widget.onSettingsChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Agent Level Webhook URL
        const Text(
          'Agent Level Webhook URL',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const Text(
          'Webhook URL to receive events from Retell. (Learn more)',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: _webhookUrl),
          onChanged: (value) {
            setState(() => _webhookUrl = value);
            _updateSettings(); // 👈 ADD THIS
          },
          // controller: _webhookUrlController,
          decoration: InputDecoration(
            hintText: 'https://your-webhook-url.com',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),

          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 24),

        // Webhook Timeout
        const Text(
          'Webhook Timeout',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const Text(
          'Set the maximum time to wait for a webhook response before timing out.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Slider(
          value: _timeoutSeconds,
          min: 1.0,
          max: 15.0,
          divisions: 14,
          label: '${_timeoutSeconds.toInt()}s',
          onChanged: (value) {
            setState(() {
              _timeoutSeconds = value;
            });
            _updateSettings(); // 👈 ADD THIS

          },
        ),
        // Show current value
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${_timeoutSeconds.toInt()} seconds',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}