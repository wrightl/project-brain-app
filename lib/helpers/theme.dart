import 'package:flutter/material.dart';
import 'package:projectbrain/utils/Colors.dart';

ThemeData getTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: HexColor.fromHex('#7291DF')),
  );
}

// TODO: Create dark theme
ThemeData getDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: HexColor.fromHex('#7291DF')),
  );
}
