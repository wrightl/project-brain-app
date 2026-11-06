import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectbrain/helpers/themes/contrast.dart';
import 'package:projectbrain/helpers/themes/design_palette.dart';

/// WCAG AA: 4.5:1 for body text.
const _aa = 4.5;

void main() {
  group('text colours meet WCAG AA', () {
    final cases = <String, (Color, Color)>{
      'muted text on background': (DesignPalette.textMuted, DesignPalette.bg),
      'muted text on surface': (DesignPalette.textMuted, DesignPalette.surface),
      'secondary text on background': (
        DesignPalette.textSecondary,
        DesignPalette.bg
      ),
      'dark muted text on dark surface': (
        DesignPalette.darkTextMuted,
        DesignPalette.darkSurface
      ),
      'dark muted text on dark background': (
        DesignPalette.darkTextMuted,
        DesignPalette.darkBg
      ),
      'on-primary text on primary': (
        DesignPalette.onPrimary,
        DesignPalette.primary
      ),
      // Dark theme uses dark text on its light purple primary.
      'dark primary button text': (
        DesignPalette.textPrimary,
        DesignPalette.darkPrimary
      ),
    };
    cases.forEach((name, pair) {
      test(name, () {
        expect(contrastRatio(pair.$1, pair.$2), greaterThanOrEqualTo(_aa));
      });
    });
  });

  group('readableOn', () {
    test('darkens accent text until it passes on its soft fill', () {
      for (final (accent, soft) in [
        (DesignPalette.amber, DesignPalette.amberSoft),
        (DesignPalette.green, DesignPalette.greenSoft),
        (DesignPalette.coral, DesignPalette.coralSoft),
        (DesignPalette.teal, DesignPalette.tealSoft),
        (DesignPalette.sky, DesignPalette.skySoft),
      ]) {
        expect(contrastRatio(readableOn(accent, soft), soft),
            greaterThanOrEqualTo(_aa));
      }
    });

    test('leaves colours that already pass alone', () {
      expect(
        readableOn(DesignPalette.textPrimary, DesignPalette.bg),
        DesignPalette.textPrimary,
      );
    });
  });
}
