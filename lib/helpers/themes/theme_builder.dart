import 'package:flutter/material.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/helpers/themes/theme_tokens.dart';

ThemeData buildAppTheme({
  required ColorScheme colorScheme,
  required AppThemeExtension extension,
}) {
  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    cardTheme: CardThemeData(
      elevation: AppCard.elevation,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.circularMd),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
    ),
    extensions: [extension],
    textTheme: const TextTheme(
      displaySmall: TextStyle(
          fontSize: AppTextSizes.displaySmall,
          fontWeight: FontWeight.w400,
          letterSpacing: 0),
      headlineLarge: TextStyle(
          fontSize: AppTextSizes.headlineLarge, fontWeight: FontWeight.w400),
      headlineMedium: TextStyle(
          fontSize: AppTextSizes.headlineMedium, fontWeight: FontWeight.w400),
      headlineSmall: TextStyle(
          fontSize: AppTextSizes.headlineSmall, fontWeight: FontWeight.w400),
      titleLarge: TextStyle(
          fontSize: AppTextSizes.titleLarge, fontWeight: FontWeight.w500),
      titleMedium: TextStyle(
          fontSize: AppTextSizes.titleMedium, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(
          fontSize: AppTextSizes.titleSmall, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(fontSize: AppTextSizes.bodyLarge),
      bodyMedium: TextStyle(fontSize: AppTextSizes.bodyMedium),
      bodySmall: TextStyle(fontSize: AppTextSizes.bodySmall),
      labelLarge: TextStyle(
          fontSize: AppTextSizes.labelLarge, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(
          fontSize: AppTextSizes.labelMedium, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(
          fontSize: AppTextSizes.labelSmall, fontWeight: FontWeight.w500),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: AppButton.padding,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.circularSm),
        textStyle: const TextStyle(
          fontSize: AppTextSizes.titleMedium,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}
