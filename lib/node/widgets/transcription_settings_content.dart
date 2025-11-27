// lib/node/widgets/transcription_settings_content.dart
import 'package:flutter/material.dart';

import '../models/global_settings.dart';

class TranscriptionSettingsContent extends StatefulWidget {
  // const TranscriptionSettingsContent({super.key});

  final GlobalSettings settings;
  final VoidCallback? onSettingsChanged;

  const TranscriptionSettingsContent({
    super.key,
    required this.settings,
    this.onSettingsChanged,
  });

  @override
  State<TranscriptionSettingsContent> createState() =>
      _TranscriptionSettingsContentState();
}

class _TranscriptionSettingsContentState
    extends State<TranscriptionSettingsContent> {
  // Denoising Mode
  // String _denoisingMode = 'noise'; // 'noise' or 'noise_speech'

  // Transcription Mode
  // String _transcriptionMode = 'speed'; // 'speed' or 'accuracy'

  // Vocabulary Specialization
  // String _vocabulary = 'general'; // 'general' or 'medical'

  late String _denoisingMode;
  late String _transcriptionMode;
  late String _vocabulary;

  @override
  void initState() {
    super.initState();
    final s = widget.settings;
    _denoisingMode = s.denoisingMode;
    _transcriptionMode = s.transcriptionMode;
    _vocabulary = s.vocabulary;
  }

  void _updateSettings() {
    widget.settings
      ..denoisingMode = _denoisingMode
      ..transcriptionMode = _transcriptionMode
      ..vocabulary = _vocabulary;
    widget.onSettingsChanged?.call();
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Denoising Mode
        const Text(
          'Denoising Mode',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const Text(
          'Filter out unwanted background noise or speech. (Learn more)',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        RadioListTile<String>(
          title: const Text('Remove noise'),
          value: 'noise',
          groupValue: _denoisingMode,
          onChanged: (value) {
            setState(() => _denoisingMode = value!);
            _updateSettings();
          },
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
        RadioListTile<String>(
          title: const Text('Remove noise + background speech'),
          value: 'noise_speech',
          groupValue: _denoisingMode,
          onChanged: (value) {
            setState(() => _denoisingMode = value!);
            _updateSettings();
          },
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(height: 24),

        // Transcription Mode
        const Text(
          'Transcription Mode',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const Text(
          'Balance between speed and accuracy. (Learn more)',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        RadioListTile<String>(
          title: const Text('Optimize for speed'),
          value: 'speed',
          groupValue: _transcriptionMode,
          onChanged: (value) {
            setState(() => _transcriptionMode = value!);
            _updateSettings();
          },
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
        RadioListTile<String>(
          title: const Text('Optimize for accuracy'),
          value: 'accuracy',
          groupValue: _transcriptionMode,
          onChanged: (value) {
            setState(() => _transcriptionMode = value!);
            _updateSettings();
          },
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(height: 24),

        // Vocabulary Specialization
        const Text(
          'Vocabulary Specialization',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const Text(
          'Choose the vocabulary set to use for transcription.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        RadioListTile<String>(
          title: const Text('General (Works well across most industries)'),
          value: 'general',
          groupValue: _vocabulary,
          onChanged: (value) {
            setState(() => _vocabulary = value!);
            _updateSettings();
          },
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
        RadioListTile<String>(
          title: const Text('Medical (Optimized for healthcare terms)'),
          value: 'medical',
          groupValue: _vocabulary,
          onChanged: (value) {
            setState(() => _vocabulary = value!);
            _updateSettings();
          },
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}