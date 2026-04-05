import 'package:flutter/material.dart';
import 'package:projectbrain/utils/colors.dart';

// Design tokens
const double kCardRadius = 12.0;
const double kCardElevation = 1.0;
const EdgeInsets kCardPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);

/// Light theme configuration (clean, lower saturation)
ThemeData getTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF6750A4),
    brightness: Brightness.light,
    primaryContainer: const Color(0xFFEADDFF),
    surfaceContainerHighest: const Color(0xFFE6E0E9),
  );

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,

    // Card theme
    cardTheme: CardThemeData(
      elevation: kCardElevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kCardRadius)),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
    ),

    extensions: [
      AppThemeExtension(
        devBadgeColor: Colors.orange,
        stagingBadgeColor: Colors.blue,
        errorColor: colorScheme.error,
        debugTextColor: colorScheme.error,
        streakColor: const Color(0xFF2E7D32),
        achievementColor: const Color(0xFFF9A825),
      ),
    ],

    textTheme: TextTheme(
      displaySmall: const TextStyle(fontSize: 36, fontWeight: FontWeight.w400, letterSpacing: 0),
      headlineLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.w400),
      headlineMedium: const TextStyle(fontSize: 28, fontWeight: FontWeight.w400),
      headlineSmall: const TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
      titleLarge: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
      titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      titleSmall: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      bodyLarge: const TextStyle(fontSize: 16),
      bodyMedium: const TextStyle(fontSize: 14),
      bodySmall: const TextStyle(fontSize: 12),
      labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      labelMedium: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}

/// Colorful theme (higher saturation, vibrant accents)
ThemeData getColorfulTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFFE65100),
    brightness: Brightness.light,
    primary: const Color(0xFFE65100),
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFFFCC80),
    onPrimaryContainer: const Color(0xFF5D2100),
    secondary: const Color(0xFF00897B),
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFB2DFDB),
    tertiary: const Color(0xFF7B1FA2),
    surface: const Color(0xFFFFF8E1),
    onSurface: const Color(0xFF1C1B1F),
    surfaceContainerHighest: const Color(0xFFF5E6C8),
  );

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,

    cardTheme: CardThemeData(
      elevation: kCardElevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kCardRadius)),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
    ),

    extensions: [
      AppThemeExtension(
        devBadgeColor: Colors.orange,
        stagingBadgeColor: Colors.blue,
        errorColor: colorScheme.error,
        debugTextColor: colorScheme.error,
        streakColor: const Color(0xFF1B5E20),
        achievementColor: const Color(0xFFFFAB00),
      ),
    ],

    textTheme: TextTheme(
      displaySmall: const TextStyle(fontSize: 36, fontWeight: FontWeight.w400, letterSpacing: 0),
      headlineLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.w400),
      headlineMedium: const TextStyle(fontSize: 28, fontWeight: FontWeight.w400),
      headlineSmall: const TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
      titleLarge: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
      titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      titleSmall: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      bodyLarge: const TextStyle(fontSize: 16),
      bodyMedium: const TextStyle(fontSize: 14),
      bodySmall: const TextStyle(fontSize: 12),
      labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      labelMedium: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    useMaterial3: true,

    cardTheme: CardThemeData(
      elevation: kCardElevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kCardRadius)),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
    ),

    extensions: [
      AppThemeExtension(
        devBadgeColor: Colors.orange.shade700,
        stagingBadgeColor: Colors.blue.shade700,
        errorColor: colorScheme.error,
        debugTextColor: colorScheme.error,
        streakColor: const Color(0xFF81C784),
        achievementColor: const Color(0xFFFFD54F),
      ),
    ],

    textTheme: TextTheme(
      displaySmall: const TextStyle(fontSize: 36, fontWeight: FontWeight.w400, letterSpacing: 0),
      headlineLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.w400),
      headlineMedium: const TextStyle(fontSize: 28, fontWeight: FontWeight.w400),
      headlineSmall: const TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
      titleLarge: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
      titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      titleSmall: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      bodyLarge: const TextStyle(fontSize: 16),
      bodyMedium: const TextStyle(fontSize: 14),
      bodySmall: const TextStyle(fontSize: 12),
      labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      labelMedium: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
  final Color streakColor;
  final Color achievementColor;

  AppThemeExtension({
    required this.devBadgeColor,
    required this.stagingBadgeColor,
    required this.errorColor,
    required this.debugTextColor,
    required this.streakColor,
    required this.achievementColor,
  });

  @override
  AppThemeExtension copyWith({
    Color? devBadgeColor,
    Color? stagingBadgeColor,
    Color? errorColor,
    Color? debugTextColor,
    Color? streakColor,
    Color? achievementColor,
  }) {
    return AppThemeExtension(
      devBadgeColor: devBadgeColor ?? this.devBadgeColor,
      stagingBadgeColor: stagingBadgeColor ?? this.stagingBadgeColor,
      errorColor: errorColor ?? this.errorColor,
      debugTextColor: debugTextColor ?? this.debugTextColor,
      streakColor: streakColor ?? this.streakColor,
      achievementColor: achievementColor ?? this.achievementColor,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      devBadgeColor: Color.lerp(devBadgeColor, other.devBadgeColor, t)!,
      stagingBadgeColor: Color.lerp(stagingBadgeColor, other.stagingBadgeColor, t)!,
      errorColor: Color.lerp(errorColor, other.errorColor, t)!,
      debugTextColor: Color.lerp(debugTextColor, other.debugTextColor, t)!,
      streakColor: Color.lerp(streakColor, other.streakColor, t)!,
      achievementColor: Color.lerp(achievementColor, other.achievementColor, t)!,
    );
  }
}
