import 'package:flutter/material.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/helpers/themes/theme_builder.dart';
import 'package:projectbrain/utils/colors.dart';

/// Dark theme configuration.
class DarkTheme {
  DarkTheme._();

  static const Color streakColor = Color(0xFF81C784);
  static const Color achievementColor = Color(0xFFFFD54F);

  static ThemeData build() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: HexColor.fromHex('#7291DF'),
      brightness: Brightness.dark,
    );

    return buildAppTheme(
      colorScheme: colorScheme,
      extension: AppThemeExtension(
        devBadgeColor: Colors.orange.shade700,
        stagingBadgeColor: Colors.blue.shade700,
        errorColor: colorScheme.error,
        debugTextColor: colorScheme.error,
        streakColor: streakColor,
        achievementColor: achievementColor,
      ),
    );
  }
}
