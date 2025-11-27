// lib/node/widgets/security_fallback_settings_content.dart
import 'package:flutter/material.dart';

import '../models/global_settings.dart';

class SecurityFallbackSettingsContent extends StatefulWidget {
  // const SecurityFallbackSettingsContent({super.key});
  final GlobalSettings settings;
  final VoidCallback? onSettingsChanged;

  const SecurityFallbackSettingsContent({
    super.key,
    required this.settings,
    this.onSettingsChanged,
  });

  @override
  State<SecurityFallbackSettingsContent> createState() =>
      _SecurityFallbackSettingsContentState();
}

class _SecurityFallbackSettingsContentState
    extends State<SecurityFallbackSettingsContent> {
  // Toggles
  // bool _optInSecureUrls = false;

  late bool _optInSecureUrls;
  late String _dataStorageOption;
  late Set<String> _selectedPii;
  late List<Map<String, String>> _dynamicVars;

  @override
  void initState() {
    super.initState();
    final s = widget.settings;
    _optInSecureUrls = s.optInSecureUrls;
    _dataStorageOption = s.dataStorageOption;
    _selectedPii = Set<String>.from(s.selectedPii);
    _dynamicVars = List<Map<String, String>>.from(s.dynamicVars);
  }

  void _updateSettings() {
    widget.settings
      ..optInSecureUrls = _optInSecureUrls
      ..dataStorageOption = _dataStorageOption
      ..selectedPii = Set<String>.from(_selectedPii)
      ..dynamicVars = List<Map<String, String>>.from(_dynamicVars);
    widget.onSettingsChanged?.call();
  }
  // Data Storage Settings
  // String _dataStorageOption = 'everything'; // everything, except_pii, basic
  static const List<Map<String, String>> _dataStorageOptions = [
    {'value': 'everything', 'label': 'Everything'},
    {'value': 'except_pii', 'label': 'Everything except PII'},
    {'value': 'basic', 'label': 'Basic Attributes Only'},
  ];

  // PII categories
  final List<String> _piiCategories = [
    'Address',
    'Email',
    'Phone Number',
    'Government Identifiers',
    'SSN',
    'Passport',
    'Driver License',
    'Financial Information',
    'Credit Card',
    'Bank Account',
    'Security Credentials',
    'Password',
    'Pin',
    'Health Information',
    'Medical Id',
  ];
  // Set<String> _selectedPii = {};

  // Default Dynamic Variables
  // List<Map<String, String>> _dynamicVars = [];
  final GlobalKey _setupButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Opt In Secure URLs
        _buildToggleRow(
          title: 'Opt In Secure URLs',
          subtitle:
          'Add security signatures to URLs. The URLs expire after 24 hours. (Learn more)',
          value: _optInSecureUrls,
          onChanged: (v){
            setState(() => _optInSecureUrls = v!);
            _updateSettings();

          }
        ),
        const SizedBox(height: 16),

        // Default Dynamic Variables
        const Text(
          'Default Dynamic Variables',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const Text(
          'Set fallback values for dynamic variables across all endpoints if they are not provided.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => _showDynamicVarsDialog(context),
          icon: const Icon(Icons.build),
          label: const Text('Setup'),
        ),
        const SizedBox(height: 16),

        // Data Storage Settings
        const Text(
          'Data Storage Settings',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const Text(
          'Choose how Retell stores sensitive data (Learn more)',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        ..._dataStorageOptions.map((option) {
          return RadioListTile<String>(
            title: Text(option['label']!),
            value: option['value']!, // 👈 Add ! to assert non-null
            groupValue: _dataStorageOption,
            onChanged: (value) {
              setState(() => _dataStorageOption = value!);
              _updateSettings();

            },
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          );
        }),
        const SizedBox(height: 16),

        // Personal Info Redaction (PII)
        const Text(
          'Personal Info Redaction (PII)',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const Text(
          'Only redact the specific categories of sensitive data you choose, while preserving other call recordings, transcripts, and analytics.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          key: _setupButtonKey,
          onPressed: () => _showPiiDialog(context),
          icon: const Icon(Icons.build),
          label: const Text('Set up'),
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

  void _showDynamicVarsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Default Dynamic Variables'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ..._dynamicVars.asMap().entries.map((entry) {
                  int i = entry.key;
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(text: entry.value['name']),
                          decoration: const InputDecoration(hintText: 'Variable Name'),
                          onChanged: (value) {
                            setState(() {
                              _dynamicVars[i]['name'] = value;
                              _updateSettings();

                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(text: entry.value['value']),
                          decoration: const InputDecoration(hintText: 'Default Value'),
                          onChanged: (value) {
                            setState(() {
                              _dynamicVars[i]['value'] = value;
                              _updateSettings();

                            });
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        onPressed: () {
                          setState(() {
                            _dynamicVars.removeAt(i);
                          });
                        },
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop(); // close dialog first
                    setState(() {
                      _dynamicVars.add({'name': '', 'value': ''});
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Variable'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Save logic here
                _updateSettings();

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dynamic variables saved')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showPiiDialog(BuildContext context) {
    // Get button position for menu
    final RenderBox? button = _setupButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (button == null) return;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        button.localToGlobal(Offset.zero) & button.size,
        Offset.zero & MediaQuery.of(context).size,
      ),
      items: _piiCategories.map((category) {
        return PopupMenuItem<String>(
          value: category,
          enabled: false,
          child: CheckboxListTile(
            title: Text(category),
            value: _selectedPii.contains(category),
            // onChanged: (bool? value) {
            //   setState(() {
            //     if (value == true) {
            //       _selectedPii.add(category);
            //     } else {
            //       _selectedPii.remove(category);
            //     }
            //   });
            // },
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  _selectedPii.add(category);
                } else {
                  _selectedPii.remove(category);
                }
              });
              _updateSettings();

            },
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        );
      }).toList(),
    );
  }
}