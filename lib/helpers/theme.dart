import 'package:flutter/material.dart';
import 'package:projectbrain/utils/colors.dart';

/// Light theme configuration
ThemeData getTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: Colors.deepPurpleAccent,
    brightness: Brightness.light,
  );

  return ThemeData(
    colorScheme: colorScheme,

    // Environment badge colors (for dev/staging indicators)
    extensions: [
      AppThemeExtension(
        devBadgeColor: Colors.orange,
        stagingBadgeColor: Colors.blue,
        errorColor: colorScheme.error,
        debugTextColor: colorScheme.error,
      ),
    ],

    // Text theme
    textTheme: const TextTheme(
      bodyMedium: TextStyle(fontSize: 16),
    ),

    // Button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
  );
}

/// Dark theme configuration
ThemeData getDarkTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: HexColor.fromHex('#7291DF'),
    brightness: Brightness.dark,
  );

  return ThemeData(
    colorScheme: colorScheme,

    // Environment badge colors (for dev/staging indicators)
    extensions: [
      AppThemeExtension(
        devBadgeColor: Colors.orange.shade700,
        stagingBadgeColor: Colors.blue.shade700,
        errorColor: colorScheme.error,
        debugTextColor: colorScheme.error,
      ),
    ],

    // Text theme
    textTheme: const TextTheme(
      bodyMedium: TextStyle(fontSize: 16),
    ),

    // Button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
  );
}

/// Custom theme extension for app-specific colors
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color devBadgeColor;
  final Color stagingBadgeColor;
  final Color errorColor;
  final Color debugTextColor;

  AppThemeExtension({
    required this.devBadgeColor,
    required this.stagingBadgeColor,
    required this.errorColor,
    required this.debugTextColor,
  });

  @override
  AppThemeExtension copyWith({
    Color? devBadgeColor,
    Color? stagingBadgeColor,
    Color? errorColor,
    Color? debugTextColor,
  }) {
    return AppThemeExtension(
      devBadgeColor: devBadgeColor ?? this.devBadgeColor,
      stagingBadgeColor: stagingBadgeColor ?? this.stagingBadgeColor,
      errorColor: errorColor ?? this.errorColor,
      debugTextColor: debugTextColor ?? this.debugTextColor,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) {
      return this;
    }
    return AppThemeExtension(
      devBadgeColor: Color.lerp(devBadgeColor, other.devBadgeColor, t)!,
      stagingBadgeColor:
          Color.lerp(stagingBadgeColor, other.stagingBadgeColor, t)!,
      errorColor: Color.lerp(errorColor, other.errorColor, t)!,
      debugTextColor: Color.lerp(debugTextColor, other.debugTextColor, t)!,
    );
  }
}
