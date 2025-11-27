
import 'package:flutter/material.dart';

import 'agent_automation_screen.dart';


void main() {
  runApp(const GestureTestApp());
}

class GestureTestApp extends StatelessWidget {
  const GestureTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gesture Framework Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AgentAutomationScreen(agentName: '',),
    );
  }
}