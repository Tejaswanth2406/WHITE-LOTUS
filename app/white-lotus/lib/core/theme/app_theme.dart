import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0A1220),
      cardColor: const Color(0xFF101C2E),
      canvasColor: const Color(0xFF0D1728),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF8B7BFF),
        brightness: Brightness.dark,
      ).copyWith(
        surface: const Color(0xFF131F33),
        surfaceContainerHighest: const Color(0xFF1A2940),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
        titleMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.5,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        selectedIconTheme: IconThemeData(color: Colors.white),
        unselectedIconTheme: IconThemeData(color: Color(0xFFB7C3D9)),
        labelType: NavigationRailLabelType.selected,
      ),
    );
  }
}
