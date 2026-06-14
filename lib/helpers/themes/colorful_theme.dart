import 'package:flutter/material.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/helpers/themes/theme_builder.dart';

/// Colorful theme — aligns with Dot+Dash logo: cobalt blue field, purple→magenta gradient accents.
class ColorfulTheme {
  ColorfulTheme._();

  static const Color brandBlue = Color(0xFF2356D4);
  static const Color brandPurple = Color(0xFF6B4EE6);
  static const Color brandPink = Color(0xFFE9307A);
  static const Color primaryContainer = Color(0xFFD8E4FF);
  static const Color onPrimaryContainer = Color(0xFF0C2A6E);
  static const Color secondaryContainer = Color(0xFFE8DEFF);
  static const Color onSecondaryContainer = Color(0xFF2D1857);
  static const Color tertiaryContainer = Color(0xFFFFD6E7);
  static const Color onTertiaryContainer = Color(0xFF5C1038);
  static const Color surface = Color(0xFFF5F8FF);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color surfaceContainerHighest = Color(0xFFE5ECFA);
  static const Color streakColor = Color(0xFF1565C0);

  static ThemeData build() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: brandBlue,
      brightness: Brightness.light,
    ).copyWith(
      primary: brandBlue,
      onPrimary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: brandPurple,
      onSecondary: Colors.white,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      tertiary: brandPink,
      onTertiary: Colors.white,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceContainerHighest,
    );

    return buildAppTheme(
      colorScheme: colorScheme,
      extension: AppThemeExtension(
        devBadgeColor: Colors.orange,
        stagingBadgeColor: brandBlue,
        errorColor: colorScheme.error,
        debugTextColor: colorScheme.error,
        streakColor: streakColor,
        achievementColor: brandPink,
      ),
    );
  }
}
