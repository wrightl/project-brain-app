import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/helpers/themes/theme_tokens.dart';

ThemeData buildAppTheme({
  required ColorScheme colorScheme,
  required AppThemeExtension extension,
  Color? scaffoldBackgroundColor,
}) {
  TextStyle headingStyle({
    required double size,
    FontWeight weight = FontWeight.w700,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: 'Funnel Sans',
      fontSize: size,
      fontWeight: weight,
      color: color ?? colorScheme.onSurface,
    );
  }

  TextStyle bodyStyle({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color? color,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color ?? colorScheme.onSurfaceVariant,
    );
  }

  final textTheme = TextTheme(
    displaySmall: headingStyle(size: AppTextSizes.displaySmall),
    headlineLarge: headingStyle(size: AppTextSizes.headlineLarge),
    headlineMedium: headingStyle(size: AppTextSizes.headlineMedium),
    headlineSmall: headingStyle(size: AppTextSizes.headlineSmall),
    titleLarge: headingStyle(size: AppTextSizes.titleLarge),
    titleMedium: headingStyle(
      size: AppTextSizes.titleMedium,
      weight: FontWeight.w600,
    ),
    titleSmall: headingStyle(
      size: AppTextSizes.titleSmall,
      weight: FontWeight.w600,
    ),
    bodyLarge: bodyStyle(
      size: AppTextSizes.bodyLarge,
      color: colorScheme.onSurface,
    ),
    bodyMedium: bodyStyle(size: AppTextSizes.bodyMedium),
    bodySmall: bodyStyle(
      size: AppTextSizes.bodySmall,
      color: extension.textMuted,
    ),
    labelLarge: bodyStyle(
      size: AppTextSizes.labelLarge,
      weight: FontWeight.w600,
      color: colorScheme.onSurface,
    ),
    labelMedium: bodyStyle(
      size: AppTextSizes.labelMedium,
      weight: FontWeight.w500,
    ),
    labelSmall: bodyStyle(
      size: AppTextSizes.labelSmall,
      weight: FontWeight.w500,
      color: extension.textMuted,
    ),
  );

  final pillShape = RoundedRectangleBorder(
    borderRadius: AppRadius.circularPill,
  );

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: scaffoldBackgroundColor ?? colorScheme.surface,
    extensions: [extension],
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: scaffoldBackgroundColor ?? colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: CardThemeData(
      elevation: AppCard.elevation,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.circularLg,
        side: BorderSide(color: extension.borderColor),
      ),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.s14,
      ),
      border: OutlineInputBorder(
        borderRadius: AppRadius.circularMd,
        borderSide: BorderSide(color: extension.borderColor, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.circularMd,
        borderSide: BorderSide(color: extension.borderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.circularMd,
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      hintStyle: textTheme.bodyMedium?.copyWith(color: extension.textMuted),
    ),
    chipTheme: ChipThemeData(
      shape: pillShape,
      side: BorderSide(color: extension.borderColor, width: 1.5),
      labelStyle: textTheme.labelMedium,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        padding: AppButton.padding,
        shape: pillShape,
        textStyle: textTheme.labelLarge,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        padding: AppButton.padding,
        shape: pillShape,
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
        padding: AppButton.padding,
        shape: pillShape,
        side: BorderSide(color: extension.borderColor, width: 1.5),
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        shape: pillShape,
        textStyle: textTheme.labelLarge,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.circularLg),
    ),
    dividerTheme: DividerThemeData(
      color: extension.borderColor,
      thickness: 1,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colorScheme.primary,
      linearTrackColor: extension.primarySoft,
    ),
  );
}
