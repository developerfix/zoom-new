// lib/node/widgets/call_settings_content.dart
import 'package:flutter/material.dart';

import '../models/global_settings.dart';

class CallSettingsContent extends StatefulWidget {
  final GlobalSettings settings;
  final VoidCallback? onSettingsChanged;

  const CallSettingsContent({
    super.key,
    required this.settings,
    this.onSettingsChanged,
  });
  // const CallSettingsContent({super.key});

  @override
  State<CallSettingsContent> createState() => _CallSettingsContentState();
}

class _CallSettingsContentState extends State<CallSettingsContent> {
  // Toggles
  // bool _voiceRecognition = false;
  // bool _voicemailDetection = false;
  // bool _keypadInputDetection = false;
  // bool _terminationKey = false;
  // bool _digitLimit = false;
  // bool _endCallOnSilence = false;

  late bool _voiceRecognition;
  late bool _voicemailDetection;
  late bool _keypadInputDetection;
  late bool _terminationKey;
  late bool _digitLimit;
  late bool _endCallOnSilence;
  late double _timeoutSeconds;
  late double _endCallSilenceSeconds;
  late double _maxCallDurationSeconds;
  late double _ringCallDurationSeconds;

  // // Slider values
  // double _timeoutSeconds = 8; // 1–15s
  // double _endCallSilenceSeconds = 30; // 10s–180s (3m)
  // double _maxCallDurationSeconds = 60; // 5s–120s (2m)
  // double _ringCallDurationSeconds = 60; // 5s–120s (2m)

  @override
  void initState() {
    super.initState();
    final s = widget.settings;
    _voiceRecognition = s.voiceRecognition;
    _voicemailDetection = s.voicemailDetection;
    _keypadInputDetection = s.keypadInputDetection;
    _terminationKey = s.terminationKey;
    _digitLimit = s.digitLimit;
    _endCallOnSilence = s.endCallOnSilence;
    _timeoutSeconds = s.timeoutSeconds;
    _endCallSilenceSeconds = s.endCallSilenceSeconds;
    _maxCallDurationSeconds = s.maxCallDurationSeconds;
    _ringCallDurationSeconds = s.ringCallDurationSeconds;
  }

  void _updateSettings() {
    final s = widget.settings;
    s
      ..voiceRecognition = _voiceRecognition
      ..voicemailDetection = _voicemailDetection
      ..keypadInputDetection = _keypadInputDetection
      ..terminationKey = _terminationKey
      ..digitLimit = _digitLimit
      ..endCallOnSilence = _endCallOnSilence
      ..timeoutSeconds = _timeoutSeconds
      ..endCallSilenceSeconds = _endCallSilenceSeconds
      ..maxCallDurationSeconds = _maxCallDurationSeconds
      ..ringCallDurationSeconds = _ringCallDurationSeconds;
    widget.onSettingsChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Voice Recognition
        _buildToggleRow(
          title: 'Voice recognition',
          subtitle: 'Recognize caller voice',
          value: _voiceRecognition,
          onChanged: (v) {
            setState(() => _voiceRecognition = v ?? false);
            _updateSettings(); // ✅ ADD THIS
          },
          // onChanged: (v) => setState(() => _voiceRecognition = v!),
        ),
        const SizedBox(height: 12),

        // Voicemail Detection
        _buildToggleRow(
          title: 'Voicemail Detection',
          subtitle: 'Hang up or leave a voicemail if a voicemail is detected.',
          value: _voicemailDetection,
          onChanged: (v) {
            setState(() => _voicemailDetection = v!);
            _updateSettings(); // ✅ ADD THIS

          }
        ),
        const SizedBox(height: 12),

        // Keypad Input Detection
        _buildToggleRow(
          title: 'User Keypad Input Detection',
          subtitle: 'Enable the AI to listen for keypad input during a call.',
          value: _keypadInputDetection,
          onChanged: (v){
            setState(() => _keypadInputDetection = v!);
            _updateSettings(); // ✅ ADD THIS

          }
        ),
        const SizedBox(height: 12),

        // Timeout
        _buildSliderRow(
          title: 'Timeout',
          subtitle: 'The AI will respond if no keypad input is detected within the set time.',
          value: _timeoutSeconds,
          min: 1,
          max: 15,
          divisions: 14,
          unit: 's',
          onChanged: (v) {
            setState(() => _timeoutSeconds = v);
            _updateSettings(); // ✅ ADD THIS
          },
        ),
        const SizedBox(height: 12),

        // Termination Key
        _buildToggleRow(
          title: 'Termination Key',
          subtitle: 'The AI will respond when the user presses the configured termination key (0-9, #, *).',
          value: _terminationKey,
          onChanged: (v) {
            setState(() => _terminationKey = v!);
            _updateSettings(); // ✅ ADD THIS

          }
        ),
        const SizedBox(height: 12),

        // Digit Limit
        _buildToggleRow(
          title: 'Digit Limit',
          subtitle: 'The AI will respond immediately after the caller enters the configured number of digits.',
          value: _digitLimit,
          onChanged: (v) {
            setState(() => _digitLimit = v!);
            _updateSettings(); // ✅ ADD THIS

          }

        ),
        const SizedBox(height: 12),

        // End Call on Silence
        _buildSliderRow(
          title: 'End Call on Silence',
          subtitle: 'End the call if user stays silent for extended period of time.',
          value: _endCallSilenceSeconds,
          min: 10,
          max: 180, // 3 minutes = 180 seconds
          divisions: 170,
          unit: 's',
          valueFormatter: (v) {
            if (v < 60) return '${v.toInt()}s';
            return '${(v / 60).toInt()}m ${(v % 60).toInt()}s';
          },
          onChanged: (v) {
            setState(() => _endCallSilenceSeconds = v);
            _updateSettings(); // ✅ ADD THIS

          }
        ),
        const SizedBox(height: 12),

        // Max Call Duration
        _buildSliderRow(
          title: 'Max Call Duration',
          subtitle: 'Maximum allowed call duration.',
          value: _maxCallDurationSeconds,
          min: 5,
          max: 120, // 2 minutes = 120 seconds
          divisions: 115,
          unit: 's',
          valueFormatter: (v) {
            if (v < 60) return '${v.toInt()}s';
            return '${(v / 60).toInt()}m ${(v % 60).toInt()}s';
          },
          onChanged: (v){
            setState(() => _maxCallDurationSeconds = v);
            _updateSettings(); // ✅ ADD THIS

          }
        ),
        _buildSliderRow(
          title: 'Ring Duration',
          subtitle: 'The max ringing duration before the outbound call / transfer call is deemed no answer.',
          value: _ringCallDurationSeconds,
          min: 5,
          max: 120, // 2 minutes = 120 seconds
          divisions: 115,
          unit: 's',
          valueFormatter: (v) {
            if (v < 60) return '${v.toInt()}s';
            return '${(v / 60).toInt()}m ${(v % 60).toInt()}s';
          },
          onChanged: (v) {
            setState(() => _ringCallDurationSeconds = v);
            _updateSettings(); // ✅ ADD THIS

          }
        ),
      ],
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSliderRow({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String unit,
    ValueChanged<double>? onChanged,
    String Function(double)? valueFormatter,
  }) {
    String displayValue = valueFormatter != null
        ? valueFormatter(value)
        : '${value.toInt()}$unit';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: displayValue,
          onChanged: onChanged,
        ),
        // Show current value below slider
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            displayValue,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}