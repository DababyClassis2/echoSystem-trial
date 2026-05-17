import 'package:flutter/material.dart';
import 'router.dart';
import 'theme.dart';

class EchoSystemApp extends StatelessWidget {
  const EchoSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'echoSystem',
      theme: EchoTheme.build(),
      home: const SizedBox.shrink(), // temporary placeholder
  );
  }
}
