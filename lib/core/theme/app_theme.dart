import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00E5FF),
        secondary: Color(0xFF7C3AED),
        surface: Color(0xFF0D1117),
        surfaceContainerLowest: Color(0xFF080B10),
        onPrimary: Color(0xFF080B10),
        onSurface: Color(0xFFCDD9E5),
      ),
      scaffoldBackgroundColor: const Color(0xFF080B10),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Color(0xFF0D1117),
        indicatorColor: Color(0xFF1E2D3D),
      ),
      fontFamily: 'monospace',
    );
  }
}
