import 'package:flutter/material.dart';
import 'package:projectbrain/helpers/themes/design_palette.dart';

/// Custom theme extension for app-specific colors beyond [ColorScheme].
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color devBadgeColor;
  final Color stagingBadgeColor;
  final Color errorColor;
  final Color debugTextColor;
  final Color streakColor;
  final Color achievementColor;
  final Color primarySoft;
  final Color borderColor;
  final Color textMuted;
  final Color teal;
  final Color tealSoft;
  final Color amber;
  final Color amberSoft;
  final Color green;
  final Color greenSoft;
  final Color coral;
  final Color coralSoft;
  final Color sky;
  final Color skySoft;

  AppThemeExtension({
    required this.devBadgeColor,
    required this.stagingBadgeColor,
    required this.errorColor,
    required this.debugTextColor,
    required this.streakColor,
    required this.achievementColor,
    required this.primarySoft,
    required this.borderColor,
    required this.textMuted,
    required this.teal,
    required this.tealSoft,
    required this.amber,
    required this.amberSoft,
    required this.green,
    required this.greenSoft,
    required this.coral,
    required this.coralSoft,
    required this.sky,
    required this.skySoft,
  });

  factory AppThemeExtension.light({ColorScheme? colorScheme}) {
    return AppThemeExtension(
      devBadgeColor: Colors.orange,
      stagingBadgeColor: Colors.blue,
      errorColor: colorScheme?.error ?? DesignPalette.error,
      debugTextColor: colorScheme?.error ?? DesignPalette.error,
      streakColor: DesignPalette.amber,
      achievementColor: DesignPalette.green,
      primarySoft: DesignPalette.primarySoft,
      borderColor: DesignPalette.border,
      textMuted: DesignPalette.textMuted,
      teal: DesignPalette.teal,
      tealSoft: DesignPalette.tealSoft,
      amber: DesignPalette.amber,
      amberSoft: DesignPalette.amberSoft,
      green: DesignPalette.green,
      greenSoft: DesignPalette.greenSoft,
      coral: DesignPalette.coral,
      coralSoft: DesignPalette.coralSoft,
      sky: DesignPalette.sky,
      skySoft: DesignPalette.skySoft,
    );
  }

  factory AppThemeExtension.dark({ColorScheme? colorScheme}) {
    return AppThemeExtension(
      devBadgeColor: Colors.orange.shade700,
      stagingBadgeColor: Colors.blue.shade700,
      errorColor: colorScheme?.error ?? DesignPalette.error,
      debugTextColor: colorScheme?.error ?? DesignPalette.error,
      streakColor: const Color(0xFFFFB74D),
      achievementColor: const Color(0xFF81C784),
      primarySoft: DesignPalette.darkPrimarySoft,
      borderColor: DesignPalette.darkBorder,
      textMuted: DesignPalette.darkTextMuted,
      teal: const Color(0xFF4DD0C8),
      tealSoft: const Color(0xFF1A3D3A),
      amber: const Color(0xFFFFB74D),
      amberSoft: const Color(0xFF3D3020),
      green: const Color(0xFF66BB6A),
      greenSoft: const Color(0xFF1E3A28),
      coral: const Color(0xFFFF8A9A),
      coralSoft: const Color(0xFF3D2028),
      sky: const Color(0xFF64B5F6),
      skySoft: const Color(0xFF1A2E42),
    );
  }

  @override
  AppThemeExtension copyWith({
    Color? devBadgeColor,
    Color? stagingBadgeColor,
    Color? errorColor,
    Color? debugTextColor,
    Color? streakColor,
    Color? achievementColor,
    Color? primarySoft,
    Color? borderColor,
    Color? textMuted,
    Color? teal,
    Color? tealSoft,
    Color? amber,
    Color? amberSoft,
    Color? green,
    Color? greenSoft,
    Color? coral,
    Color? coralSoft,
    Color? sky,
    Color? skySoft,
  }) {
    return AppThemeExtension(
      devBadgeColor: devBadgeColor ?? this.devBadgeColor,
      stagingBadgeColor: stagingBadgeColor ?? this.stagingBadgeColor,
      errorColor: errorColor ?? this.errorColor,
      debugTextColor: debugTextColor ?? this.debugTextColor,
      streakColor: streakColor ?? this.streakColor,
      achievementColor: achievementColor ?? this.achievementColor,
      primarySoft: primarySoft ?? this.primarySoft,
      borderColor: borderColor ?? this.borderColor,
      textMuted: textMuted ?? this.textMuted,
      teal: teal ?? this.teal,
      tealSoft: tealSoft ?? this.tealSoft,
      amber: amber ?? this.amber,
      amberSoft: amberSoft ?? this.amberSoft,
      green: green ?? this.green,
      greenSoft: greenSoft ?? this.greenSoft,
      coral: coral ?? this.coral,
      coralSoft: coralSoft ?? this.coralSoft,
      sky: sky ?? this.sky,
      skySoft: skySoft ?? this.skySoft,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      devBadgeColor: Color.lerp(devBadgeColor, other.devBadgeColor, t)!,
      stagingBadgeColor:
          Color.lerp(stagingBadgeColor, other.stagingBadgeColor, t)!,
      errorColor: Color.lerp(errorColor, other.errorColor, t)!,
      debugTextColor: Color.lerp(debugTextColor, other.debugTextColor, t)!,
      streakColor: Color.lerp(streakColor, other.streakColor, t)!,
      achievementColor:
          Color.lerp(achievementColor, other.achievementColor, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      teal: Color.lerp(teal, other.teal, t)!,
      tealSoft: Color.lerp(tealSoft, other.tealSoft, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      amberSoft: Color.lerp(amberSoft, other.amberSoft, t)!,
      green: Color.lerp(green, other.green, t)!,
      greenSoft: Color.lerp(greenSoft, other.greenSoft, t)!,
      coral: Color.lerp(coral, other.coral, t)!,
      coralSoft: Color.lerp(coralSoft, other.coralSoft, t)!,
      sky: Color.lerp(sky, other.sky, t)!,
      skySoft: Color.lerp(skySoft, other.skySoft, t)!,
    );
  }
}

extension AppThemeExtensionContext on BuildContext {
  AppThemeExtension get appTheme =>
      Theme.of(this).extension<AppThemeExtension>() ??
      AppThemeExtension.light(colorScheme: Theme.of(this).colorScheme);
}
