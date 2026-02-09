import 'package:flutter/material.dart';

/// Production-ready theme configurations for the app
class AppThemes {
  // Prevent instantiation
  AppThemes._();

  /* ============================================================
     MODERN BLUE THEME (Professional & Trust-worthy)
     ============================================================ */

  static final ThemeData modernBlueLight = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF1565C0), // Deep blue
      secondary: Color(0xFF0277BD), // Light blue
      tertiary: Color(0xFF00ACC1), // Cyan accent
      error: Color(0xFFD32F2F),
      surface: Color(0xFFFAFAFA),
      onSurface: Color(0xFF212121),
      surfaceContainerHighest: Color(0xFFE3F2FD),
      outline: Color(0xFFBDBDBD),
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1565C0),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      floatingLabelStyle: const TextStyle(color: Color(0xFF1565C0)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF1565C0),
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
    ),
  );

  static final ThemeData modernBlueDark = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF42A5F5), // Lighter blue for dark mode
      secondary: Color(0xFF29B6F6),
      tertiary: Color(0xFF26C6DA),
      error: Color(0xFFEF5350),
      surface: Color(0xFF1E1E1E),
      onSurface: Color(0xFFE0E0E0),
      surfaceContainerHighest: Color(0xFF2C2C2C),
      outline: Color(0xFF616161),
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Color(0xFFE0E0E0),
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      floatingLabelStyle: const TextStyle(color: Color(0xFF42A5F5)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF42A5F5), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF424242)),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF42A5F5),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF42A5F5),
      foregroundColor: Colors.black,
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF2C2C2C),
    ),
  );

  /* ============================================================
     PURPLE THEME (Creative & Modern)
     ============================================================ */

  static final ThemeData purpleLight = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF6A1B9A), // Deep purple
      secondary: Color(0xFF8E24AA),
      tertiary: Color(0xFFAB47BC),
      error: Color(0xFFC62828),
      surface: Color(0xFFFAFAFA),
      onSurface: Color(0xFF212121),
      surfaceContainerHighest: Color(0xFFF3E5F5),
      outline: Color(0xFFBDBDBD),
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF6A1B9A),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      floatingLabelStyle: const TextStyle(color: Color(0xFF6A1B9A)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6A1B9A), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF6A1B9A),
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
    ),
  );

  static final ThemeData purpleDark = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFBA68C8),
      secondary: Color(0xFFCE93D8),
      tertiary: Color(0xFFE1BEE7),
      error: Color(0xFFEF5350),
      surface: Color(0xFF1E1E1E),
      onSurface: Color(0xFFE0E0E0),
      surfaceContainerHighest: Color(0xFF2C2C2C),
      outline: Color(0xFF616161),
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Color(0xFFE0E0E0),
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      floatingLabelStyle: const TextStyle(color: Color(0xFFBA68C8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFBA68C8), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF424242)),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFBA68C8),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFBA68C8),
      foregroundColor: Colors.black,
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF2C2C2C),
    ),
  );

  /* ============================================================
     GREEN THEME (Fresh & Natural)
     ============================================================ */

  static final ThemeData greenLight = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF2E7D32), // Forest green
      secondary: Color(0xFF388E3C),
      tertiary: Color(0xFF66BB6A),
      error: Color(0xFFD32F2F),
      surface: Color(0xFFFAFAFA),
      onSurface: Color(0xFF212121),
      surfaceContainerHighest: Color(0xFFE8F5E9),
      outline: Color(0xFFBDBDBD),
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2E7D32),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      floatingLabelStyle: const TextStyle(color: Color(0xFF2E7D32)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF2E7D32),
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
    ),
  );

  static final ThemeData greenDark = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF66BB6A),
      secondary: Color(0xFF81C784),
      tertiary: Color(0xFFA5D6A7),
      error: Color(0xFFEF5350),
      surface: Color(0xFF1E1E1E),
      onSurface: Color(0xFFE0E0E0),
      surfaceContainerHighest: Color(0xFF2C2C2C),
      outline: Color(0xFF616161),
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Color(0xFFE0E0E0),
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      floatingLabelStyle: const TextStyle(color: Color(0xFF66BB6A)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF66BB6A), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF424242)),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF66BB6A),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF66BB6A),
      foregroundColor: Colors.black,
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF2C2C2C),
    ),
  );

  /* ============================================================
     ORANGE THEME (Energetic & Warm)
     ============================================================ */

  static final ThemeData orangeLight = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFE65100), // Deep orange
      secondary: Color(0xFFEF6C00),
      tertiary: Color(0xFFF57C00),
      error: Color(0xFFD32F2F),
      surface: Color(0xFFFAFAFA),
      onSurface: Color(0xFF212121),
      surfaceContainerHighest: Color(0xFFFFF3E0),
      outline: Color(0xFFBDBDBD),
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFE65100),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      floatingLabelStyle: const TextStyle(color: Color(0xFFE65100)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE65100), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFE65100),
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
    ),
  );

  static final ThemeData orangeDark = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFFF9800),
      secondary: Color(0xFFFFB74D),
      tertiary: Color(0xFFFFCC80),
      error: Color(0xFFEF5350),
      surface: Color(0xFF1E1E1E),
      onSurface: Color(0xFFE0E0E0),
      surfaceContainerHighest: Color(0xFF2C2C2C),
      outline: Color(0xFF616161),
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Color(0xFFE0E0E0),
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      floatingLabelStyle: const TextStyle(color: Color(0xFFFF9800)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF9800), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF424242)),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF9800),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFFF9800),
      foregroundColor: Colors.black,
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF2C2C2C),
    ),
  );

  /* ============================================================
     INDIGO THEME (Professional & Calm)
     ============================================================ */

  static final ThemeData indigoLight = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF283593), // Deep indigo
      secondary: Color(0xFF3949AB),
      tertiary: Color(0xFF5C6BC0),
      error: Color(0xFFD32F2F),
      surface: Color(0xFFFAFAFA),
      onSurface: Color(0xFF212121),
      surfaceContainerHighest: Color(0xFFE8EAF6),
      outline: Color(0xFFBDBDBD),
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF283593),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      floatingLabelStyle: const TextStyle(color: Color(0xFF283593)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF283593), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF283593),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF283593),
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
    ),
  );

  static final ThemeData indigoDark = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF5C6BC0),
      secondary: Color(0xFF7986CB),
      tertiary: Color(0xFF9FA8DA),
      error: Color(0xFFEF5350),
      surface: Color(0xFF1E1E1E),
      onSurface: Color(0xFFE0E0E0),
      surfaceContainerHighest: Color(0xFF2C2C2C),
      outline: Color(0xFF616161),
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Color(0xFFE0E0E0),
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      floatingLabelStyle: const TextStyle(color: Color(0xFF5C6BC0)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF5C6BC0), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF424242)),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5C6BC0),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF5C6BC0),
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF2C2C2C),
    ),
  );
}

/// Enum to identify available themes
enum AppThemeType { modernBlue, purple, green, orange, indigo }

/// Extension to get theme data from enum
extension AppThemeTypeExtension on AppThemeType {
  ThemeData getLightTheme() {
    switch (this) {
      case AppThemeType.modernBlue:
        return AppThemes.modernBlueLight;
      case AppThemeType.purple:
        return AppThemes.purpleLight;
      case AppThemeType.green:
        return AppThemes.greenLight;
      case AppThemeType.orange:
        return AppThemes.orangeLight;
      case AppThemeType.indigo:
        return AppThemes.indigoLight;
    }
  }

  ThemeData getDarkTheme() {
    switch (this) {
      case AppThemeType.modernBlue:
        return AppThemes.modernBlueDark;
      case AppThemeType.purple:
        return AppThemes.purpleDark;
      case AppThemeType.green:
        return AppThemes.greenDark;
      case AppThemeType.orange:
        return AppThemes.orangeDark;
      case AppThemeType.indigo:
        return AppThemes.indigoDark;
    }
  }

  String get displayName {
    switch (this) {
      case AppThemeType.modernBlue:
        return 'Modern Blue';
      case AppThemeType.purple:
        return 'Purple';
      case AppThemeType.green:
        return 'Green';
      case AppThemeType.orange:
        return 'Orange';
      case AppThemeType.indigo:
        return 'Indigo';
    }
  }
}
