import 'package:flutter/material.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/helpers/themes/design_palette.dart';
import 'package:projectbrain/helpers/themes/theme_builder.dart';

/// Default light theme — ProjectBrain design system.
class LightTheme {
  LightTheme._();

  static ThemeData build() {
    final colorScheme = ColorScheme.light(
      primary: DesignPalette.primary,
      onPrimary: DesignPalette.onPrimary,
      primaryContainer: DesignPalette.primarySoft,
      onPrimaryContainer: DesignPalette.primary,
      secondary: DesignPalette.teal,
      onSecondary: DesignPalette.onPrimary,
      secondaryContainer: DesignPalette.tealSoft,
      onSecondaryContainer: DesignPalette.teal,
      tertiary: DesignPalette.coral,
      onTertiary: DesignPalette.onPrimary,
      tertiaryContainer: DesignPalette.coralSoft,
      onTertiaryContainer: DesignPalette.coral,
      error: DesignPalette.error,
      onError: DesignPalette.onPrimary,
      surface: DesignPalette.surface,
      onSurface: DesignPalette.textPrimary,
      onSurfaceVariant: DesignPalette.textSecondary,
      outline: DesignPalette.border,
      outlineVariant: DesignPalette.border,
      surfaceContainerHighest: DesignPalette.border,
    );

    return buildAppTheme(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: DesignPalette.bg,
      extension: AppThemeExtension.light(colorScheme: colorScheme),
    );
  }
}
