import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_themes.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  AppThemeType _selectedTheme = AppThemeType.modernBlue;

  bool get isDarkMode => _isDarkMode;
  AppThemeType get selectedTheme => _selectedTheme;

  ThemeProvider() {
    _loadPreferences();
  }

  /// Get the current light theme based on selected theme type
  ThemeData get lightTheme => _selectedTheme.getLightTheme();

  /// Get the current dark theme based on selected theme type
  ThemeData get darkTheme => _selectedTheme.getDarkTheme();

  /// Load saved preferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;

    final themeIndex = prefs.getInt('selectedTheme') ?? 0;
    _selectedTheme = AppThemeType.values[themeIndex];

    notifyListeners();
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  /// Change the color theme
  Future<void> setTheme(AppThemeType theme) async {
    _selectedTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedTheme', theme.index);
    notifyListeners();
  }
}
