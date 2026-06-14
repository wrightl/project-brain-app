import 'package:flutter/material.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/helpers/themes/theme_builder.dart';

/// Dot + Dash theme — brand palette from dotanddashconsulting.com.
class DotDashTheme {
  DotDashTheme._();

  static const Color inkNavy = Color(0xFF171D3A);
  static const Color pinkLilac = Color(0xFFF598FF);
  static const Color periwinkle = Color(0xFF94ABF9);
  static const Color softLavender = Color(0xFFE5E9FD);
  static const Color secondaryContainer = Color(0xFFFFECF5);
  static const Color tertiaryContainer = Color(0xFFF4F6FF);

  static ThemeData build() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: inkNavy,
      brightness: Brightness.light,
    ).copyWith(
      primary: inkNavy,
      onPrimary: Colors.white,
      primaryContainer: softLavender,
      onPrimaryContainer: inkNavy,
      secondary: pinkLilac,
      onSecondary: inkNavy,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: inkNavy,
      tertiary: periwinkle,
      onTertiary: inkNavy,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: inkNavy,
      surface: Colors.white,
      onSurface: inkNavy,
      surfaceContainerHighest: softLavender,
    );

    return buildAppTheme(
      colorScheme: colorScheme,
      extension: AppThemeExtension(
        devBadgeColor: Colors.orange,
        stagingBadgeColor: periwinkle,
        errorColor: colorScheme.error,
        debugTextColor: colorScheme.error,
        streakColor: periwinkle,
        achievementColor: pinkLilac,
      ),
    );
  }
}
