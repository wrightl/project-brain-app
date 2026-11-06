import 'package:flutter/material.dart';

/// WCAG contrast ratio between two opaque colours (1 to 21).
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

/// [foreground], darkened on a light [background] (or lightened on a dark
/// one) just enough to reach [minRatio]. Accent colours that work for icons
/// often fail as text on their own soft fill; this keeps the hue.
Color readableOn(Color foreground, Color background, {double minRatio = 4.5}) {
  if (contrastRatio(foreground, background) >= minRatio) return foreground;
  final target =
      background.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  for (var t = 0.05; t <= 1.0; t += 0.05) {
    final candidate = Color.lerp(foreground, target, t)!;
    if (contrastRatio(candidate, background) >= minRatio) return candidate;
  }
  return target;
}
