import 'package:flutter/material.dart';

/// Custom theme extension for app-specific colors.
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
