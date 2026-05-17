import 'package:flutter/material.dart';

class EchoColors {
  static const Color chromeBlueGrey = Color(0xFF4A5B6E);
  static const Color navySlate = Color(0xFF2C3E50);
  static const Color pewter = Color(0xFF6B7B8D);
  static const Color icyWhite = Color(0xFFF5F7FA);
  static const Color warmGold = Color(0xFFD4C4A8);
  static const Color deepNavy = Color(0xFF1A252F);
}

final appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: EchoColors.chromeBlueGrey,
    secondary: EchoColors.warmGold,
    surface: EchoColors.navySlate,
    background: EchoColors.navySlate,
    error: Colors.redAccent,
  ),
  scaffoldBackgroundColor: EchoColors.navySlate,
);
