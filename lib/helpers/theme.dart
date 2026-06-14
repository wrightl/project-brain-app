import 'package:flutter/material.dart';
import 'package:projectbrain/helpers/themes/colorful_theme.dart';
import 'package:projectbrain/helpers/themes/dark_theme.dart';
import 'package:projectbrain/helpers/themes/dotdash_theme.dart';
import 'package:projectbrain/helpers/themes/light_theme.dart';

export 'themes/app_theme_extension.dart';
export 'themes/colorful_theme.dart';
export 'themes/dark_theme.dart';
export 'themes/dotdash_theme.dart';
export 'themes/light_theme.dart';
export 'themes/theme_tokens.dart';

/// Light theme configuration (clean, lower saturation).
ThemeData getTheme() => LightTheme.build();

/// Colorful theme — aligns with Dot+Dash logo.
ThemeData getColorfulTheme() => ColorfulTheme.build();

/// Dot + Dash theme — brand palette from dotanddashconsulting.com.
ThemeData getDotDashTheme() => DotDashTheme.build();

/// Dark theme configuration.
ThemeData getDarkTheme() => DarkTheme.build();
