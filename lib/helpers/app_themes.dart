import 'package:flutter/material.dart';
import 'package:projectbrain/helpers/themes/colorful_theme.dart';
import 'package:projectbrain/helpers/themes/dark_theme.dart';
import 'package:projectbrain/helpers/themes/dotdash_theme.dart';
import 'package:projectbrain/helpers/themes/light_theme.dart';

class AppThemeOption {
  final String id;
  final String label;
  final IconData icon;
  final ThemeMode themeMode;
  final ThemeData Function() build;

  const AppThemeOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.themeMode,
    required this.build,
  });
}

class AppThemes {
  static const String defaultId = 'system';

  static final List<AppThemeOption> all = [
    AppThemeOption(
      id: 'light',
      label: 'Light',
      icon: Icons.light_mode,
      themeMode: ThemeMode.light,
      build: LightTheme.build,
    ),
    AppThemeOption(
      id: 'colorful',
      label: 'Colorful',
      icon: Icons.palette,
      themeMode: ThemeMode.light,
      build: ColorfulTheme.build,
    ),
    AppThemeOption(
      id: 'dotdash',
      label: 'Dot + Dash',
      icon: Icons.brush,
      themeMode: ThemeMode.light,
      build: DotDashTheme.build,
    ),
    AppThemeOption(
      id: 'dark',
      label: 'Dark',
      icon: Icons.dark_mode,
      themeMode: ThemeMode.dark,
      build: DarkTheme.build,
    ),
    AppThemeOption(
      id: 'system',
      label: 'System',
      icon: Icons.brightness_auto,
      themeMode: ThemeMode.system,
      build: LightTheme.build,
    ),
  ];

  static bool isValid(String id) => all.any((option) => option.id == id);

  static AppThemeOption byId(String id) {
    return all.firstWhere(
      (option) => option.id == id,
      orElse: () => all.firstWhere((option) => option.id == defaultId),
    );
  }
}
