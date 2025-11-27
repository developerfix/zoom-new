// lib/node/widgets/add_event_dialog.dart
import 'dart:convert';

import 'package:flutter/material.dart';

// Data class to hold configured event
class ConfiguredEvent {
  final String type;
  final Map<String, dynamic> config;

  ConfiguredEvent(this.type, this.config);
}

class AddEventDialog extends StatefulWidget {
  const AddEventDialog({super.key});

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  int? _selectedIndex;    // NEW: tracks which configured event is selected
  String? _selectedEvent; // still used for dropdown selection
  final List<ConfiguredEvent> _configuredEvents = [];

  // Show form dialog based on event type
  Future<void> _showEventForm(String eventType) async {
    final config = await _showEventConfigDialog(context, eventType);
    if (config != null) {
      setState(() {
        _configuredEvents.add(ConfiguredEvent(eventType, config));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // reduced from default ~20–28 → boxy but slightly rounded
      ),
      title: const Text('Select EVENT'),
      content: SizedBox(
        // Increase max height of content area
        height: 400, // adjust as needed
        width: 500,  // this works together with insetPadding
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose an event source:', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedEvent,
              hint: const Text('Select an option'),
              items: const [
                DropdownMenuItem(value: 'calendar', child: Text('Calendar')),
                DropdownMenuItem(value: 'sheetspeed', child: Text('Sheetspeed')),
                DropdownMenuItem(value: 'customize', child: Text('Customize')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedEvent = value;
                });
                if (value != null) {
                  _showEventForm(value);
                }
              },

              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              ),

            ),
            const SizedBox(height: 16),
            if (_configuredEvents.isNotEmpty)
              const Text('Configured Events:', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._configuredEvents.asMap().entries.map((entry) {
              final index = entry.key;
              final event = entry.value;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedIndex == index ? Colors.blue : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      title: Text(_getEventDisplayName(event.type)),
                      subtitle: Text(_formatConfigSummary(event.config)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () async {
                              final updatedConfig = await _showEventConfigDialog(
                                context,
                                event.type,
                                initialConfig: event.config,
                              );
                              if (updatedConfig != null) {
                                setState(() {
                                  _configuredEvents[index] = ConfiguredEvent(event.type, updatedConfig);
                                });
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18),
                            onPressed: () {
                              setState(() {
                                _configuredEvents.removeAt(index);
                                if (_selectedIndex == index) {
                                  _selectedIndex = null;
                                } else if (_selectedIndex != null && _selectedIndex! > index) {
                                  _selectedIndex = _selectedIndex! - 1;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedIndex != null
              ? () {
            // Return only the selected event
            Navigator.of(context).pop([_configuredEvents[_selectedIndex!]]);
          }
              : null,
          child: const Text('Save'),
        ),
      ],
      actionsAlignment: MainAxisAlignment.spaceBetween,
    );
  }

  String _getEventDisplayName(String type) {
    switch (type) {
      case 'calendar': return 'Calendar Event';
      case 'sheetspeed': return 'Sheetspeed Trigger';
      case 'customize': return 'Custom Event';
      default: return type;
    }
  }

  String _formatConfigSummary(Map<String, dynamic> config) {
    if (config.isEmpty) return 'No configuration';
    return config.entries.map((e) => '${e.key}: ${e.value}').take(2).join(', ');
  }

  Future<Map<String, dynamic>?> _showEventConfigDialog(
      BuildContext context,
      String eventType, {
        Map<String, dynamic>? initialConfig,
      }) async {
    switch (eventType)
    {
      case 'calendar':
        return await _showCalendarForm(context, initialConfig);
      case 'sheetspeed':
        return await _showSheetspeedForm(context, initialConfig);
      case 'customize':
        return await _showCustomizeForm(context, initialConfig);
      default:
        return null;
    }
  }

  Future<Map<String, dynamic>?> _showCalendarForm(
      BuildContext context, Map<String, dynamic>? initial) async {
    final nameController = TextEditingController(text: initial?['name'] ?? '');
    final descriptionController = TextEditingController(text: initial?['description'] ?? '');
    final apiKeyController = TextEditingController(text: initial?['apiKey'] ?? '');
    final eventTypeIdController = TextEditingController(text: initial?['eventTypeId'] ?? '');
    final timezoneController = TextEditingController(text: initial?['timezone'] ?? '');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // 👈 matches main dialog
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.95, // 95% of screen width
            maxHeight: MediaQuery.sizeOf(context).height * 0.7, // 70% of screen height
          ), // 👈 same as main dialog
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 👇 Icon + Title at top
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Configure Calendar Event',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
            
                // ===== NAME =====
                Text('Name', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8), // 👈 boxy curve
                    ),
                  ),
                ),
                const SizedBox(height: 16),
            
                // ===== DESCRIPTION =====
                Text('Description', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  'Provide a short description for this event trigger',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: descriptionController,
                  maxLines: 3, // 👈 taller text area
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
            
                // ===== API KEY =====
                Text('API Key (Cal.com)', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  'Find this in your Cal.com developer settings',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: apiKeyController,
                  obscureText: true,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
            
                // ===== EVENT TYPE ID =====
                Text('Event Type ID (Cal.com)', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 6),
                TextField(
                  controller: eventTypeIdController,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
            
                // ===== TIMEZONE =====
                Text('Timezone', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 6),
                TextField(
                  controller: timezoneController,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'name': nameController.text,
                'description': descriptionController.text,
                'apiKey': apiKeyController.text,
                'eventTypeId': eventTypeIdController.text,
                'timezone': timezoneController.text,
              });
            },
            child: const Text('Save'),
          ),
        ],
        actionsAlignment: MainAxisAlignment.end,
      ),
    );
    return result;
  }
  Future<Map<String, dynamic>?> _showSheetspeedForm(
      BuildContext context, Map<String, dynamic>? initial) async {
    final sheetIdController = TextEditingController(text: initial?['sheetId'] ?? '');
    final triggerController = TextEditingController(text: initial?['trigger'] ?? '');
    final apiKeyController = TextEditingController(text: initial?['apiKey'] ?? '');
    final rangeController = TextEditingController(text: initial?['range'] ?? 'A1:Z1000');
    final pollIntervalController = TextEditingController(text: initial?['pollInterval'] ?? '60');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // matches main dialog
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        content:ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.95, // 95% of screen width
            maxHeight: MediaQuery.sizeOf(context).height * 0.7, // 70% of screen height
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 👇 Icon + Title
                Row(
                  children: [
                    const Icon(Icons.grid_on, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Configure Sheetspeed Trigger',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
            
                // ===== GOOGLE SHEET ID =====
                Text('Google Sheet ID', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  'Found in the URL of your Google Sheet',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: sheetIdController,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
            
                // ===== API KEY (for Google Sheets API) =====
                Text('Google API Key', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  'Required for read access (optional if sheet is public)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: apiKeyController,
                  obscureText: true,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
            
                // ===== TRIGGER CONDITION =====
                Text('Trigger Condition', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 6),
                TextField(
                  controller: triggerController,
                  decoration: InputDecoration(
                    hintText: 'e.g., "When column B changes"',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
            
                // ===== DATA RANGE =====
                Text('Data Range', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  'Range to monitor (default: A1:Z1000)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: rangeController,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
            
                // ===== POLLING INTERVAL =====
                Text('Poll Interval (seconds)', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  'How often to check for changes (min: 30)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: pollIntervalController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'sheetId': sheetIdController.text,
                'apiKey': apiKeyController.text,
                'trigger': triggerController.text,
                'range': rangeController.text,
                'pollInterval': pollIntervalController.text,
              });
            },
            child: const Text('Save'),
          ),
        ],
        actionsAlignment: MainAxisAlignment.end,
      ),
    );
    return result;
  }
  Future<Map<String, dynamic>?> _showCustomizeForm(
      BuildContext context, Map<String, dynamic>? initial) async
  {
    // ===== FIX 1: Define helper function FIRST =====
    List<Map<String, String>> _parseInitialPairs(dynamic input) {
      if (input == null) return [];
      if (input is String) {
        try {
          final map = json.decode(input) as Map<String, dynamic>;
          return map.entries
              .map((e) => {
            'key': e.key.toString(),
            'value': e.value.toString(),
          })
              .toList();
        } catch (e) {
          return [];
        }
      } else if (input is Map) {
        return input.entries
            .map((e) => {
          'key': e.key.toString(),
          'value': e.value.toString(),
        })
            .toList();
      }
      return [];
    }

    // ===== Now safe to use _parseInitialPairs =====
    final nameController = TextEditingController(text: initial?['name'] ?? '');
    final descriptionController = TextEditingController(text: initial?['description'] ?? '');
    final apiEndpointController = TextEditingController(text: initial?['apiEndpoint'] ?? '');
    final timeoutController = TextEditingController(text: initial?['timeout'] ?? '5000');

    List<Map<String, String>> _headers = _parseInitialPairs(initial?['headers']);
    List<Map<String, String>> _queryParams = _parseInitialPairs(initial?['queryParams']);
    List<Map<String, String>> _responseVars = _parseInitialPairs(initial?['responseVars']);
    String _method = initial?['method'] ?? 'GET';

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          Widget _buildKeyValueSection(
              String title,
              String subtitle,
              List<Map<String, String>> pairs,
              void Function() onAdd,
              void Function(int) onDelete,
              ) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 8),
                ...pairs.asMap().entries.map((entry) {
                  final i = entry.key;
                  final pair = entry.value;
                  final keyCtrl = TextEditingController(text: pair['key'] ?? '');
                  final valCtrl = TextEditingController(text: pair['value'] ?? '');

                  keyCtrl.addListener(() {
                    pairs[i]['key'] = keyCtrl.text;
                  });
                  valCtrl.addListener(() {
                    pairs[i]['value'] = valCtrl.text;
                  });

                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: keyCtrl,
                          decoration: InputDecoration(
                            hintText: 'Key',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: valCtrl,
                          decoration: InputDecoration(
                            hintText: 'Value',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => onDelete(i),
                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                      ),
                    ],
                  );
                }).toList(),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      backgroundColor: Colors.grey[200],
                    ),
                    onPressed: onAdd,
                    child: const Text('New Key-Value Pair', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          }
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // ✅ keeps your box curve
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: 500,
                maxWidth: MediaQuery.sizeOf(context).width < 500
                    ? double.infinity
                    : 650, // ✅ wider on desktop
                maxHeight: MediaQuery.sizeOf(context).height * 0.75,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.sizeOf(context).width < 500 ? 16 : 24,
                    vertical: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Title Row ---
                      Row(
                        children: [
                          const Icon(Icons.functions, color: Colors.purple),
                          const SizedBox(width: 8),
                          Text(
                            'Custom Function',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // --- Rest of your fields (exactly as before) ---
                      Text('Name', style: Theme.of(context).textTheme.bodyMedium),
                      Text('Name', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text('Description', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 6),
                      TextField(
                        controller: descriptionController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ===== API ENDPOINT WITH METHOD =====
                      Text('API Endpoint', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text(
                        'The API Endpoint is the address of the service you are connecting to',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          SizedBox(
                            width: 90,
                            child: DropdownButtonFormField<String>(
                              isExpanded: true, // 👈 forces dropdown to use full width
                              value: _method,
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              items: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE']
                                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                                  .toList(),
                              onChanged: (v) => setState(() => _method = v!),
                              // ⚠️ REMOVED dropdownStyle & menuProps — not available in older Flutter
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: apiEndpointController,
                              decoration: InputDecoration(
                                hintText: 'https://api.example.com/endpoint',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Text('Timeout (ms)', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 6),
                      TextField(
                        controller: timeoutController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildKeyValueSection(
                        'Headers',
                        'Specify the HTTP headers required for your API request.',
                        _headers,
                            () => setState(() => _headers.add({'key': '', 'value': ''})),
                            (i) => setState(() => _headers.removeAt(i)),
                      ),

                      _buildKeyValueSection(
                        'Query Parameters',
                        'Query string parameters to append to the URL.',
                        _queryParams,
                            () => setState(() => _queryParams.add({'key': '', 'value': ''})),
                            (i) => setState(() => _queryParams.removeAt(i)),
                      ),

                      _buildKeyValueSection(
                        'Response Variables',
                        'Extracted values from API response saved as dynamic variables.',
                        _responseVars,
                            () => setState(() => _responseVars.add({'key': '', 'value': ''})),
                            (i) => setState(() => _responseVars.removeAt(i)),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Map<String, String> _pairsToMap(List<Map<String, String>> pairs) {
                                final map = <String, String>{};
                                for (var p in pairs) {
                                  final k = p['key']?.trim();
                                  final v = p['value']?.trim();
                                  if (k != null && k.isNotEmpty && v != null) {
                                    map[k] = v;
                                  }
                                }
                                return map;
                              }

                              Navigator.pop(context, {
                                'name': nameController.text,
                                'description': descriptionController.text,
                                'method': _method,
                                'apiEndpoint': apiEndpointController.text,
                                'timeout': timeoutController.text,
                                'headers': _pairsToMap(_headers),
                                'queryParams': _pairsToMap(_queryParams),
                                'responseVars': _pairsToMap(_responseVars),
                              });
                            },
                            child: const Text('Save'),
                          ),
                        ],
                      ),

                    ],


                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

}