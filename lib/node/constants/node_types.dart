// lib/node/constants/node_types.dart
import 'package:flutter/material.dart';

class NodeTypes {
  static const List<Map<String, dynamic>> all = [
    {'key': 'conversation',       'name': 'Conversation',      'icon': Icons.record_voice_over},
    {'key': 'add_event',          'name': 'Add Event',         'icon': Icons.add_circle},
    {'key': 'call_start',         'name': 'Call start',        'icon': Icons.phone_in_talk},
    {'key': 'call_end',           'name': 'Call end',          'icon': Icons.phone_callback},
    {'key': 'call_transfer',      'name': 'Call transfer',     'icon': Icons.call_missed_outgoing},
    {'key': 'api_request',        'name': 'Api request',       'icon': Icons.api},
    {'key': 'extract_variable',   'name': 'Extract variable',  'icon': Icons.find_in_page},
    {'key': 'voice_record',        'name': 'voice record',       'icon': Icons.mic},
    {'key': 'press_digit',        'name': 'Press digit',       'icon': Icons.dialpad},
    {'key': 'logic_split',        'name': 'Logic split node',  'icon': Icons.join_inner},
    {'key': 'sms',                'name': 'SMS',               'icon': Icons.message},
    {'key': 'chat_bot',           'name': 'Chat BOT',          'icon': Icons.chat},
  ];
}