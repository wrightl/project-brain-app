import 'package:flutter/material.dart';
import 'package:projectbrain/core/storage/preferences_service.dart';
import 'package:projectbrain/helpers/theme.dart';

/// Provider for app theme mode (light / colorful / dark / system).
/// Resolves [theme], [darkTheme], and [themeMode] for [MaterialApp].
class ThemeModeProvider extends ChangeNotifier {
  final PreferencesService _preferences;

  ThemeModeProvider(this._preferences);

  /// Current stored mode: 'light' | 'colorful' | 'dark' | 'system'
  String get mode => _preferences.themeMode;

  /// Light or colorful theme for [ThemeMode.light]
  ThemeData get theme {
    switch (mode) {
      case 'colorful':
        return getColorfulTheme();
      default:
        return getTheme();
    }
  }

  /// Dark theme
  ThemeData get darkTheme => getDarkTheme();

  /// [ThemeMode] for [MaterialApp.themeMode]
  ThemeMode get themeMode {
    switch (mode) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  /// Set theme mode and notify listeners
  Future<void> setMode(String value) async {
    if (value == mode) return;
    await _preferences.setThemeMode(value);
    notifyListeners();
  }
}
