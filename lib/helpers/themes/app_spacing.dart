import 'package:flutter/material.dart';

/// Base spacing scale (4px grid + named outliers).
abstract class AppSpacing {
  static const double micro = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  // Outliers — preserve exact UI, do not normalize
  static const double s5 = 5;
  static const double s6 = 6;
  static const double s10 = 10;
  static const double s14 = 14;
  static const double s20 = 20;
  static const double s28 = 28;
  static const double emptyStateOffset = 80;
  static const double emptyStateTop = 120;
}

/// Border radius values and pre-built BorderRadius objects.
abstract class AppRadius {
  static const double xs = 2;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 20;

  static final BorderRadius circularSm = BorderRadius.circular(sm);
  static final BorderRadius circularMd = BorderRadius.circular(md);
  static final BorderRadius circularLg = BorderRadius.circular(lg);
  static final BorderRadius circularPill = BorderRadius.circular(pill);
}

/// Common EdgeInsets presets built from [AppSpacing].
abstract class AppInsets {
  static const EdgeInsets page = EdgeInsets.all(AppSpacing.xl);
  static const EdgeInsets screen = EdgeInsets.all(AppSpacing.lg);
  static const EdgeInsets card = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.md,
  );
  static const EdgeInsets listItemBottom =
      EdgeInsets.only(bottom: AppSpacing.md);
  static const EdgeInsets button = EdgeInsets.symmetric(
    horizontal: AppSpacing.xl,
    vertical: AppSpacing.md,
  );
  static const EdgeInsets chip = EdgeInsets.symmetric(
    horizontal: AppSpacing.sm,
    vertical: AppSpacing.xs,
  );
}

/// SizedBox gap helpers.
abstract class AppGap {
  static SizedBox h(double size) => SizedBox(height: size);
  static SizedBox w(double size) => SizedBox(width: size);

  static SizedBox get sm => SizedBox(height: AppSpacing.sm);
  static SizedBox get md => SizedBox(height: AppSpacing.md);
  static SizedBox get lg => SizedBox(height: AppSpacing.lg);
  static SizedBox get xl => SizedBox(height: AppSpacing.xl);
}

/// Component-level card spacing.
abstract class AppCard {
  static const double radius = AppRadius.md;
  static const double elevation = 1.0;
  static const EdgeInsets padding = AppInsets.card;
}

/// Component-level button spacing.
abstract class AppButton {
  static const EdgeInsets padding = AppInsets.button;
  static const double radius = AppRadius.sm;
  static const double elevation = 1;
}
