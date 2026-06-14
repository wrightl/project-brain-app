import 'package:flutter/material.dart';
import 'package:projectbrain/core/storage/preferences_service.dart';
import 'package:projectbrain/helpers/app_themes.dart';
import 'package:projectbrain/helpers/themes/dark_theme.dart';
import 'package:projectbrain/helpers/themes/light_theme.dart';

/// Provider for app theme mode (light / colorful / dotdash / dark / system).
/// Resolves [theme], [darkTheme], and [themeMode] for [MaterialApp].
class ThemeModeProvider extends ChangeNotifier {
  final PreferencesService _preferences;

  ThemeModeProvider(this._preferences);

  /// Current stored mode id from [AppThemes].
  String get mode => _preferences.themeMode;

  /// Light theme for [ThemeMode.light] (or fallback when using dark/system).
  ThemeData get theme {
    final option = AppThemes.byId(mode);
    return option.themeMode == ThemeMode.light
        ? option.build()
        : LightTheme.build();
  }

  /// Dark theme
  ThemeData get darkTheme => DarkTheme.build();

  /// [ThemeMode] for [MaterialApp.themeMode]
  ThemeMode get themeMode => AppThemes.byId(mode).themeMode;

  /// Set theme mode and notify listeners
  Future<void> setMode(String value) async {
    if (value == mode) return;
    await _preferences.setThemeMode(value);
    notifyListeners();
  }
}
