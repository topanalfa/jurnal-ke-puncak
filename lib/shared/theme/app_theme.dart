import 'package:flutter/material.dart';

class AppTheme {
  // Forest color palette
  static const Color forestGreen = Color(0xFF2D5A27);
  static const Color mossGreen = Color(0xFF4A7C59);
  static const Color sageGreen = Color(0xFF8BA888);
  static const Color barkBrown = Color(0xFF5D4037);
  static const Color dirtBrown = Color(0xFF8D6E63);
  static const Color cream = Color(0xFFF5F0E8);
  static const Color warmWhite = Color(0xFFFFFBF5);
  static const Color amberAccent = Color(0xFFD4A574);

  static ThemeData get forest {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: forestGreen,
        onPrimary: warmWhite,
        primaryContainer: sageGreen,
        onPrimaryContainer: forestGreen,
        secondary: barkBrown,
        onSecondary: warmWhite,
        secondaryContainer: dirtBrown,
        onSecondaryContainer: cream,
        tertiary: amberAccent,
        onTertiary: forestGreen,
        surface: warmWhite,
        onSurface: barkBrown,
        error: const Color(0xFFB71C1C),
        onError: warmWhite,
      ),
      scaffoldBackgroundColor: cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: forestGreen,
        foregroundColor: warmWhite,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: warmWhite,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: mossGreen,
        foregroundColor: warmWhite,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: warmWhite,
        selectedItemColor: forestGreen,
        unselectedItemColor: dirtBrown,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: forestGreen,
          foregroundColor: warmWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: warmWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: sageGreen),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: forestGreen, width: 2),
        ),
      ),
    );
  }
}
