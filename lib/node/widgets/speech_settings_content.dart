// lib/node/widgets/speech_settings_content.dart
import 'package:flutter/material.dart';

import '../models/global_settings.dart';

class SpeechSettingsContent extends StatefulWidget {
  // const SpeechSettingsContent({super.key});

  final GlobalSettings settings;
  final VoidCallback? onSettingsChanged;

  const SpeechSettingsContent({
    super.key,
    required this.settings,
    this.onSettingsChanged,
  });

  @override
  State<SpeechSettingsContent> createState() => _SpeechSettingsContentState();
}

class _SpeechSettingsContentState extends State<SpeechSettingsContent> {
  // String? _backgroundSound = 'None';
  // double _responsiveness = 0.5;
  // double _interruptionSensitivity = 0.5;
  // bool _backchanneling = false;
  // bool _speechNormalization = false;
  // String _reminderSeconds = '30';

  late String _backgroundSound;
  late double _responsiveness;
  late double _interruptionSensitivity;
  late bool _backchanneling;
  late bool _speechNormalization;
  late String _reminderSeconds;


  @override
  void initState() {
    super.initState();
    final settings = widget.settings;
    _backgroundSound = settings.backgroundSound;
    _responsiveness = settings.responsiveness;
    _interruptionSensitivity = settings.interruptionSensitivity;
    _backchanneling = settings.backchanneling;
    _speechNormalization = settings.speechNormalization;
    _reminderSeconds = settings.reminderSeconds;
  }

  @override
  void didUpdateWidget(SpeechSettingsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.settings != oldWidget.settings) {
      final settings = widget.settings;
      setState(() {
        _backgroundSound = settings.backgroundSound;
        _responsiveness = settings.responsiveness;
        _interruptionSensitivity = settings.interruptionSensitivity;
        _backchanneling = settings.backchanneling;
        _speechNormalization = settings.speechNormalization;
        _reminderSeconds = settings.reminderSeconds;
      });
    }
  }

  void _updateSettings() {
    widget.settings
      ..backgroundSound = _backgroundSound
      ..responsiveness = _responsiveness
      ..interruptionSensitivity = _interruptionSensitivity
      ..backchanneling = _backchanneling
      ..speechNormalization = _speechNormalization
      ..reminderSeconds = _reminderSeconds;
    widget.onSettingsChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Background Sound
        Row(
          children: [
            Text(
              'Background Sound',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Material(
                color: Colors.blue.shade600,
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () async {
                    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                    if (renderBox == null) return;
                    final Offset offset = renderBox.localToGlobal(Offset.zero);

                    final value = await showMenu<String>(
                      context: context,
                      position: RelativeRect.fromRect(
                        Rect.fromPoints(offset, offset + const Offset(150, 40)),
                        Offset.zero & MediaQuery.of(context).size,
                      ),
                      items: [
                        'None',
                        'Office',
                        'Cafe',
                        'Street',
                        'Forest',
                      ].map((sound) {
                        return PopupMenuItem(
                          value: sound,
                          child: Text(
                            sound,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      elevation: 4,
                    );
                    //
                    // if (value != null) {
                    //   setState(() => _backgroundSound = value);
                    // }
                    if (value != null) {
                      setState(() {
                        _backgroundSound = value;
                      });
                      _updateSettings(); // 👈 ADD THIS
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _backgroundSound ?? 'None',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.settings, size: 18, color: Colors.white),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Background sound settings')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Responsiveness
        const Text(
          'Responsiveness',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const Text(
          'Control how fast the agent responds after users finish speaking.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Slider(
          value: _responsiveness,
          min: 0.0,
          max: 1.0,
          divisions: 10,
          label: _responsiveness < 0.33
              ? 'Slow'
              : _responsiveness < 0.66
              ? 'Medium'
              : 'Fast',
          // onChanged: (value) {
          //   setState(() => _responsiveness = value);
          // },
          onChanged: (value) {
            setState(() => _responsiveness = value);
            _updateSettings(); // 👈 ADD THIS
          },
        ),
        const SizedBox(height: 16),

        // Interruption Sensitivity
        const Text(
          'Interruption Sensitivity',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const Text(
          'Control how sensitively AI can be interrupted by human speech.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Slider(
          value: _interruptionSensitivity,
          min: 0.0,
          max: 1.0,
          divisions: 10,
          label: _interruptionSensitivity < 0.33
              ? 'Low'
              : _interruptionSensitivity < 0.66
              ? 'Medium'
              : 'High',
          // onChanged: (value) {
          //   setState(() => _interruptionSensitivity = value);
          // },
          onChanged: (value) {
            setState(() => _interruptionSensitivity = value);
            _updateSettings(); // 👈 ADD THIS
          },
        ),
        const SizedBox(height: 16),

        // Enable Backchanneling
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enable Backchanneling',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                  const Text(
                    'Enables the agent to use affirmations like \'yeah\' or \'uh-huh\' during conversations, indicating active listening and engagement.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Switch(
              value: _backchanneling,
              onChanged: (value) {
                setState(() => _backchanneling = value);
                _updateSettings(); // 👈 ADD THIS

              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Enable Speech Normalization
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enable Speech Normalization',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                  const Text(
                    'It converts text elements like numbers, currency, and dates into human-like spoken forms. (Learn more)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Switch(
              value: _speechNormalization,
              onChanged: (value) {
                setState(() => _speechNormalization = value);
                _updateSettings(); // 👈 ADD THIS

              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Reminder Message Frequency
        const Text(
          'Reminder Message Frequency',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const Text(
          'Control how often AI will send a reminder message',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Row(
          children: [
            SizedBox(
              width: 50,
              child: TextField(
                controller: TextEditingController(text: _reminderSeconds),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: '30',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  if (RegExp(r'^\d*$').hasMatch(value)) {
                    setState(() => _reminderSeconds = value);
                    _updateSettings(); // 👈 ADD THIS

                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            const Text('seconds'),
            const SizedBox(width: 8),

            SizedBox(
              width: 50,
              child: TextField(
                controller: TextEditingController(text: _reminderSeconds),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: '30',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  if (RegExp(r'^\d*$').hasMatch(value)) {
                    setState(() => _reminderSeconds = value);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),

            const Text('Time'),


          ],
        ),
        const SizedBox(height: 16),

        // Pronunciation
        const Text(
          'Pronunciation',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const Text(
          'Guide the model to pronounce a word, name, or phrase in a specific way. (Learn more)',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add'),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add pronunciation guide')),
            );
          },
        ),
      ],
    );
  }
}