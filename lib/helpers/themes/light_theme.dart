import 'package:flutter/material.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/helpers/themes/theme_builder.dart';

/// Light theme configuration (clean, lower saturation).
class LightTheme {
  LightTheme._();

  static const Color seedColor = Color(0xFF6750A4);
  static const Color primaryContainer = Color(0xFFEADDFF);
  static const Color surfaceContainerHighest = Color(0xFFE6E0E9);
  static const Color streakColor = Color(0xFF2E7D32);
  static const Color achievementColor = Color(0xFFF9A825);

  static ThemeData build() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      primaryContainer: primaryContainer,
      surfaceContainerHighest: surfaceContainerHighest,
    );

    return buildAppTheme(
      colorScheme: colorScheme,
      extension: AppThemeExtension(
        devBadgeColor: Colors.orange,
        stagingBadgeColor: Colors.blue,
        errorColor: colorScheme.error,
        debugTextColor: colorScheme.error,
        streakColor: streakColor,
        achievementColor: achievementColor,
      ),
    );
  }
}
