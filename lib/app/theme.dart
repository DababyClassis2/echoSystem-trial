import 'package:flutter/material.dart';

class EchoColors {
  EchoColors._();

  static const Color chromeBlueGrey = Color(0xFF4A5B6E);
  static const Color navySlate = Color(0xFF2C3E50);
  static const Color deepNavy = Color(0xFF1A252F);
  static const Color pewter = Color(0xFF6B7B8D);
  static const Color icyWhite = Color(0xFFF5F7FA);
  static const Color warmGold = Color(0xFFD4C4A8);

  static const List<int> avatarPalette = [
    0xFF4A5B6E, 0xFF2C3E50, 0xFF6B7B8D,
    0xFFD4C4A8, 0xFF5D8AA8, 0xFF8DA399,
    0xFF7B6D8D, 0xFF9E7B4A, 0xFF4A7B6E,
    0xFF8D4A4A, 0xFF5A6E4A, 0xFF6E4A6B,
  ];
}

class EchoTheme {
  EchoTheme._();

  static ThemeData build() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: EchoColors.chromeBlueGrey,
        secondary: EchoColors.warmGold,
        surface: EchoColors.navySlate,
        error: Colors.redAccent,
      ),
      scaffoldBackgroundColor: EchoColors.navySlate,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: EchoColors.icyWhite,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: EchoColors.icyWhite),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: EchoColors.warmGold,
        unselectedItemColor: EchoColors.pewter,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: EchoColors.icyWhite, fontSize: 16),
        bodyMedium: TextStyle(color: EchoColors.pewter, fontSize: 14),
        titleLarge: TextStyle(color: EchoColors.icyWhite, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: EchoColors.chromeBlueGrey.withValues(alpha: 0.3),
        selectedColor: EchoColors.warmGold.withValues(alpha: 0.3),
        labelStyle: const TextStyle(color: EchoColors.icyWhite),
        side: const BorderSide(color: EchoColors.chromeBlueGrey),
      ),
    );
  }
}
