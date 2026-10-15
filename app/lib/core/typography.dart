import 'package:flutter/widgets.dart';

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

/// Minimum line height for Thai so tone marks are never clipped.
const thaiMinLineHeight = 1.45;

/// One set of text styles. Use [AppTypography.of] in widgets so Thai screens
/// get Thai-safe line heights.
class AppTypography {
  const AppTypography._({
    required this.displayXl,
    required this.displayLg,
    required this.headline,
    required this.title,
    required this.bodyLg,
    required this.bodyMd,
    required this.label,
    required this.caption,
    required this.heroLabel,
    required this.sectionHeader,
    required this.link,
    required this.rowTitle,
    required this.rowSubtitle,
    required this.footer,
    required this.tabLabel,
  });

  final TextStyle displayXl;
  final TextStyle displayLg;
  final TextStyle headline;
  final TextStyle title;
  final TextStyle bodyLg;
  final TextStyle bodyMd;
  final TextStyle label;
  final TextStyle caption;
  final TextStyle heroLabel;
  final TextStyle sectionHeader;
  final TextStyle link;
  final TextStyle rowTitle;
  final TextStyle rowSubtitle;
  final TextStyle footer;
  final TextStyle tabLabel;

  static AppTypography of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'th' ? thai : english;

  static final english = AppTypography._(
    displayXl: _style(size: 96, weight: 800, height: 1, letterSpacing: -4),
    displayLg: _style(size: 46, weight: 800, height: 1.1, letterSpacing: -1.5),
    headline: _style(size: 34, weight: 800, height: 1.25, letterSpacing: -1),
    title: _style(size: 24, weight: 800, height: 1.25, letterSpacing: -0.5),
    bodyLg: _style(size: 16, weight: 700, height: 1.4),
    bodyMd: _style(size: 15, weight: 400, height: 1.5),
    label: _style(size: 14, weight: 700, height: 1.4),
    caption: _style(size: 13, weight: 500, height: 1.4),
    heroLabel: _style(
      size: 15,
      weight: 500,
      height: 1.4,
    ).copyWith(color: AppColors.onSurfaceSecondary),
    sectionHeader: _style(
      size: 15,
      weight: 700,
      height: 1.4,
      letterSpacing: -0.2,
    ),
    link: _style(
      size: 14,
      weight: 600,
      height: 1.4,
    ).copyWith(color: AppColors.onSurfaceTertiary),
    rowTitle: _style(size: 16, weight: 600, height: 1.4),
    rowSubtitle: _style(
      size: 13,
      weight: 500,
      height: 1.4,
    ).copyWith(color: AppColors.onSurfaceTertiary),
    footer: _style(
      size: 12,
      weight: 500,
      height: 1.4,
    ).copyWith(color: AppColors.onSurfaceTertiary),
    tabLabel: _style(size: 11, weight: 600, height: 1.2),
  );

  /// Same scale with line heights of at least [thaiMinLineHeight]. Latin
  /// letters and numbers stay in Google Sans Flex so amounts look the same in
  /// both languages; Thai glyphs come from the Noto Sans Thai fallback.
  static final thai = AppTypography._(
    displayXl: english.displayXl,
    displayLg: english.displayLg,
    headline: _thaiSafe(english.headline),
    title: _thaiSafe(english.title),
    bodyLg: _thaiSafe(english.bodyLg),
    bodyMd: _thaiSafe(english.bodyMd).copyWith(height: 1.6),
    label: _thaiSafe(english.label),
    caption: _thaiSafe(english.caption),
    heroLabel: _thaiSafe(english.heroLabel),
    sectionHeader: _thaiSafe(english.sectionHeader),
    link: _thaiSafe(english.link),
    rowTitle: _thaiSafe(english.rowTitle),
    rowSubtitle: _thaiSafe(english.rowSubtitle),
    footer: _thaiSafe(english.footer),
    tabLabel: _thaiSafe(english.tabLabel),
  );

  static TextStyle _thaiSafe(TextStyle s) => s.copyWith(
    height: (s.height ?? 1) < thaiMinLineHeight ? thaiMinLineHeight : s.height,
    letterSpacing: 0,
  );

  static TextStyle _style({
    required double size,
    required int weight,
    required double height,
    double letterSpacing = 0,
  }) => TextStyle(
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
}
