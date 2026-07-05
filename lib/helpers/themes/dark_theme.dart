import 'package:flutter/material.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/helpers/themes/design_palette.dart';
import 'package:projectbrain/helpers/themes/theme_builder.dart';

/// Dark theme — derived from the ProjectBrain design system palette.
class DarkTheme {
  DarkTheme._();

  static ThemeData build() {
    final colorScheme = ColorScheme.dark(
      primary: DesignPalette.darkPrimary,
      onPrimary: DesignPalette.textPrimary,
      primaryContainer: DesignPalette.darkPrimarySoft,
      onPrimaryContainer: DesignPalette.darkPrimary,
      secondary: const Color(0xFF4DD0C8),
      onSecondary: DesignPalette.textPrimary,
      secondaryContainer: const Color(0xFF1A3D3A),
      onSecondaryContainer: const Color(0xFF4DD0C8),
      tertiary: const Color(0xFFFF8A9A),
      onTertiary: DesignPalette.textPrimary,
      tertiaryContainer: const Color(0xFF3D2028),
      onTertiaryContainer: const Color(0xFFFF8A9A),
      error: DesignPalette.error,
      onError: DesignPalette.onPrimary,
      surface: DesignPalette.darkSurface,
      onSurface: DesignPalette.darkTextPrimary,
      onSurfaceVariant: DesignPalette.darkTextSecondary,
      outline: DesignPalette.darkBorder,
      outlineVariant: DesignPalette.darkBorder,
      surfaceContainerHighest: DesignPalette.darkSurfaceHigh,
    );

    return buildAppTheme(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: DesignPalette.darkBg,
      extension: AppThemeExtension.dark(colorScheme: colorScheme),
    );
  }
}
