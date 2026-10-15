import 'package:flutter/painting.dart';

import 'colors.dart';

/// Type scale. Single source: docs/DESIGN.md `typography`.
///
/// Both bundled fonts are variable fonts, so every style sets the `wght`
/// axis explicitly as well as [FontWeight]; otherwise the engine would
/// synthesize bold instead of using the real weight.
abstract final class AppFonts {
  static const latin = 'Google Sans Flex';
  static const thai = 'Noto Sans Thai';

  /// Thai glyphs fall back to Noto Sans Thai inside Latin styles.
  static const latinFallback = [thai];
}

abstract final class AppTypography {
  static TextStyle _latin({
    required double size,
    required int weight,
    required double height,
    double letterSpacing = 0,
  }) =>
      TextStyle(
        fontFamily: AppFonts.latin,
        fontFamilyFallback: AppFonts.latinFallback,
        fontSize: size,
        fontWeight: FontWeight(weight),
        fontVariations: [FontVariation.weight(weight.toDouble())],
        height: height,
        letterSpacing: letterSpacing,
        color: AppColors.onSurface,
        // Tabular figures so amounts line up and do not jitter while counting.
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle _thai({
    required double size,
    required int weight,
    required double height,
  }) =>
      TextStyle(
        fontFamily: AppFonts.thai,
        fontSize: size,
        fontWeight: FontWeight(weight),
        fontVariations: [FontVariation.weight(weight.toDouble())],
        height: height,
        color: AppColors.onSurface,
      );

  static final displayXl =
      _latin(size: 96, weight: 800, height: 1, letterSpacing: -4);
  static final displayLg =
      _latin(size: 46, weight: 800, height: 1.1, letterSpacing: -1.5);
  static final headline =
      _latin(size: 34, weight: 800, height: 1.25, letterSpacing: -1);
  static final title =
      _latin(size: 24, weight: 800, height: 1.25, letterSpacing: -0.5);
  static final bodyLg = _latin(size: 16, weight: 700, height: 1.4);
  static final bodyMd = _latin(size: 15, weight: 400, height: 1.5);
  static final label = _latin(size: 14, weight: 700, height: 1.4);
  static final caption = _latin(size: 13, weight: 500, height: 1.4);

  static final thaiBody = _thai(size: 15, weight: 400, height: 1.6);
  static final thaiDisplay = _thai(size: 28, weight: 700, height: 1.45);
}
