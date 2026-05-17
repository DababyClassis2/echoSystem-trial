import 'package:flutter/material.dart';

void main() {
  runApp(const MinimalApp());
}

class MinimalApp extends StatelessWidget {
  const MinimalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'EchoSystem – Minimal Test\nIf you see this, Flutter is working.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, color: Colors.green),
          ),
        ),
      ),
    );
  }
}
