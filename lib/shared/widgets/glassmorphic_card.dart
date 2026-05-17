import 'package:flutter/material.dart';
import '../../app/theme.dart';

class GlassmorphicCard extends StatelessWidget {
  final String title;
  final String content;

  const GlassmorphicCard({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)],
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: EchoColors.warmGold.withOpacity(0.2), width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: EchoColors.icyWhite)),
            const SizedBox(height: 20),
            Text(content, style: const TextStyle(fontSize: 16, color: EchoColors.pewter), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
