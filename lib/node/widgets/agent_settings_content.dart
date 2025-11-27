
import 'package:flutter/material.dart';

import '../models/global_settings.dart';

class AgentSettingsContent extends StatefulWidget {
  final GlobalSettings settings;
  final VoidCallback? onSettingsChanged; // 👈 nullable

  const AgentSettingsContent({
    super.key,
    required this.settings,
    this.onSettingsChanged,
    // required this.onSettingsChanged,
  });
  // const AgentSettingsContent();

  @override
  State<AgentSettingsContent> createState() => _AgentSettingsContentState();
}

class _AgentSettingsContentState extends State<AgentSettingsContent> {
  late String _selectedVoice;
  late String _selectedLanguage;
  late String _selectedModel;
  late String _prompt;
  late String _selectedTimeZone;
  late TextEditingController _promptController; // 👈 Add this


  @override
  void didUpdateWidget(AgentSettingsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.settings != oldWidget.settings) {
      final settings = widget.settings;
      setState(() {
        _selectedVoice = settings.voice;
        _selectedLanguage = settings.language;
        _selectedModel = settings.model;
        _prompt = settings.prompt;
        _selectedTimeZone = settings.timeZone; // 👈 ADD THIS

      });
      // Synchronize controller text without losing cursor position
      if (_promptController.text != _prompt) {
        _promptController.value = TextEditingValue(
          text: _prompt,
          selection: TextSelection.collapsed(offset: _prompt.length),
        );
      }
    }
  }

  // @override
  // void didUpdateWidget(AgentSettingsContent oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   if (widget.settings != oldWidget.settings) {
  //     final settings = widget.settings;
  //     setState(() {
  //       _selectedVoice = settings.voice;
  //       _selectedLanguage = settings.language;
  //       _selectedModel = settings.model;
  //       _prompt = settings.prompt;
  //       // Also update the TextField controller if you use one
  //     });
  //   }
  // }

  @override
  void initState() {
    super.initState();
    final settings = widget.settings;
    _selectedVoice = settings.voice;
    _selectedLanguage = settings.language;
    _selectedModel = settings.model;
    _prompt = settings.prompt;
    _selectedTimeZone = settings.timeZone; // 👈 ADD THIS

    _promptController = TextEditingController(text: _prompt); // 👈 Initialize once

  }
  @override
  void dispose() {
    _promptController.dispose(); // 👈 Don't forget to dispose
    super.dispose();
  }

  void _updateSettings() {
    widget.settings
      ..voice = _selectedVoice
      ..language = _selectedLanguage
      ..model = _selectedModel
      ..prompt = _prompt
      ..timeZone = _selectedTimeZone; // 👈 ADD THIS
    widget.onSettingsChanged?.call(); // 👈 safe call with ?
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Voice
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Voice',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const Spacer(),

            // const SizedBox(width: 6),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 150),
              child: Material(
                color: Colors.blue.shade600,
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () async {
                    final value = await showMenu<String>(
                      context: context,
                      position: RelativeRect.fromRect(
                        Rect.fromPoints(
                          (context.findRenderObject() as RenderBox).localToGlobal(Offset.zero),
                          (context.findRenderObject() as RenderBox).localToGlobal(Offset(150, 40)),
                        ),
                        Offset.zero & MediaQuery.of(context).size,
                      ),
                      items: [
                        'en-US-Neural2-F',
                        'en-US-Neural2-M',
                        'en-GB-Neural2-F',
                        'fr-FR-Neural2-F',
                      ].map((voice) {
                        return PopupMenuItem(
                          value: voice,
                          child: Text(
                            voice,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      elevation: 4,
                    );
                    if (value != null) {
                      setState(() {
                        _selectedVoice = value;
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
                            _selectedVoice ?? 'Select...',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(Icons.settings, size: 18, color: Colors.white),
                          padding: const EdgeInsets.all(0),
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Voice settings')),
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
        const SizedBox(height: 12),

// Language
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Language',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 150),
              child: Material(
                color: Colors.blue.shade600,
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () async {
                    final RenderBox renderBox = context.findRenderObject() as RenderBox;
                    final Offset offset = renderBox.localToGlobal(Offset.zero);

                    final value = await showMenu<String>(
                      context: context,
                      position: RelativeRect.fromRect(
                        Rect.fromPoints(
                          offset,
                          offset + Offset(150, 40),
                        ),
                        Offset.zero & MediaQuery.of(context).size,
                      ),
                      items: [
                        'en-US',
                        'es-ES',
                        'fr-FR',
                        'de-DE',
                        'ja-JP',
                      ].map((lang) {
                        return PopupMenuItem(
                          value: lang,
                          child: Text(
                            lang,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      elevation: 4,
                    );

                    if (value != null) {
                      setState(() {
                        _selectedLanguage = value;
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
                            _selectedLanguage ?? 'Select...',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(Icons.settings, size: 18, color: Colors.white),
                          padding: const EdgeInsets.all(0),
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Language settings')),
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

        const SizedBox(height: 12),

// LLM Model
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'LLM Model',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const Spacer(),

            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 150),
              child: Material(
                color: Colors.blue.shade600,
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () async {
                    final RenderBox renderBox = context.findRenderObject() as RenderBox;
                    final Offset offset = renderBox.localToGlobal(Offset.zero);

                    final value = await showMenu<String>(
                      context: context,
                      position: RelativeRect.fromRect(
                        Rect.fromPoints(
                          offset,
                          offset + Offset(150, 40),
                        ),
                        Offset.zero & MediaQuery.of(context).size,
                      ),
                      items: [
                        'gpt-4o',
                        'gpt-4-turbo',
                        'claude-3-5-sonnet',
                        'gemini-1.5-pro',
                        'llama-3-70b',
                      ].map((model) {
                        return PopupMenuItem(
                          value: model,
                          child: Text(
                            model,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      elevation: 4,
                    );

                    if (value != null) {
                      setState(() {
                        _selectedModel = value;
                      });  _updateSettings(); // 👈 ADD THIS

                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _selectedModel ?? 'Select...',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(Icons.settings, size: 18, color: Colors.white),
                          padding: const EdgeInsets.all(0),
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('LLM settings')),
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


        // const SizedBox(height: 12),
        const SizedBox(height: 12),

// Time Zone
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Time Zone',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 150),
              child: Material(
                color: Colors.blue.shade600,
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () async {
                    final RenderBox renderBox = context.findRenderObject() as RenderBox;
                    final Offset offset = renderBox.localToGlobal(Offset.zero);

                    // Get list of time zones (you can limit this list if needed)
                    final allTimeZones = TimeZone.getKnownLocations();

                    final value = await showMenu<String>(
                      context: context,
                      position: RelativeRect.fromRect(
                        Rect.fromPoints(offset, offset + const Offset(150, 200)), // taller menu
                        Offset.zero & MediaQuery.of(context).size,
                      ),
                      items: allTimeZones.map((tz) {
                        return PopupMenuItem(
                          value: tz,
                          child: Text(
                            tz,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      elevation: 4,
                    );

                    if (value != null) {
                      setState(() {
                        _selectedTimeZone = value;
                      });
                      _updateSettings();
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _selectedTimeZone ?? 'Select...',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text(
                'Prompt',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextField(
              minLines: 10,
              maxLines: 18,
              controller: _promptController, // 👈 use persistent controller

              // controller: TextEditingController.fromValue(
              //     TextEditingValue(text: _prompt)
              // ),
              onChanged: (value) {
                setState(() => _prompt = value);
                _updateSettings(); // 👈 sync immediately
              },
              decoration: InputDecoration(
                hintText: 'Enter global prompt...',
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),

          ],
        )
      ],
    );
  }
}

class TimeZone {
  static List<String> getKnownLocations() => [
    'UTC',
    'America/New_York',
    'America/Chicago',
    'America/Denver',
    'America/Los_Angeles',
    'Europe/London',
    'Europe/Paris',
    'Asia/Tokyo',
    'Asia/Shanghai',
    'Australia/Sydney',
    // Add more as needed
  ];
}