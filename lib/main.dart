import 'package:flutter/material.dart';

import 'agent_automation_screen.dart';

void main() {
  // Performance optimizations
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GestureTestApp());
}

class GestureTestApp extends StatelessWidget {
  const GestureTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gesture Framework Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(),
      ),
      home: const AgentAutomationScreen(agentName: ''),
    );
  }
}
