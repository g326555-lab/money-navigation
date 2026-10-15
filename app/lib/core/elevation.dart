import 'package:flutter/painting.dart';

import 'colors.dart';

/// Shadow levels (DESIGN.md "Elevation & Depth"). One light source above:
/// higher levels cast longer, softer and fainter shadows. Shadows on colour
/// are tinted with that colour, never black.
abstract final class AppElevation {
  static BoxShadow _s(
    Color c,
    double a,
    double y,
    double blur, [
    double spread = 0,
  ]) => BoxShadow(
    color: c.withValues(alpha: a),
    offset: Offset(0, y),
    blurRadius: blur,
    spreadRadius: spread,
  );

  /// E0: white group cards resting on the grey page.
  static final e0 = [
    _s(AppColors.shadow, 0.03, 1, 3),
    _s(AppColors.shadow, 0.05, 6, 20, -4),
  ];

  /// E1: raised objects — hero card, dark card, primary button, icon tiles.
  static final e1 = [
    _s(AppColors.shadow, 0.06, 1, 2),
    _s(AppColors.shadow, 0.06, 4, 10),
    _s(AppColors.shadow, 0.08, 12, 24, -6),
  ];

  /// E1 on the green success field, tinted green.
  static final e1Green = [
    _s(AppColors.shadowGreen, 0.10, 2, 6),
    _s(AppColors.shadowGreen, 0.10, 6, 14),
    _s(AppColors.shadowGreen, 0.14, 16, 40, -8),
  ];

  /// E1 for a tile of colour [hue]: the shadow takes the tile's hue.
  static List<BoxShadow> e1Tinted(Color hue) => [
    _s(hue, 0.18, 1, 2),
    _s(hue, 0.22, 4, 10, -2),
  ];

  /// A white pill resting on a green surface: contact shadow only, tinted.
  static final pillOnGreen = [_s(AppColors.shadowGreen, 0.10, 1, 3)];

  /// Small round knob on a track (the price-scale marker).
  static final knob = [_s(AppColors.shadow, 0.18, 2, 6)];

  /// E1 for a green button: the shadow takes the button's own green.
  static final e1GreenButton = [
    _s(AppColors.shadowGreen, 0.16, 1, 2),
    _s(AppColors.shadowGreen, 0.14, 4, 10),
    _s(AppColors.shadowGreen, 0.16, 12, 24, -6),
  ];

  /// The soft contact shadow under the floating coin.
  static final coinContact = [
    _s(AppColors.coinShadow, 0.20, 0, 10),
    _s(AppColors.coinShadow, 0.08, 0, 28),
  ];

  /// E2: floating chrome — tab bar, action dock.
  static final e2 = [
    _s(AppColors.shadow, 0.06, 1, 2),
    _s(AppColors.shadow, 0.08, 8, 24),
    _s(AppColors.shadow, 0.10, 24, 48, -12),
  ];

  /// E2 cast upwards, for bottom sheets.
  static final e2Sheet = [
    for (final s in e2)
      BoxShadow(
        color: s.color,
        offset: Offset(0, -s.offset.dy),
        blurRadius: s.blurRadius,
        spreadRadius: s.spreadRadius,
      ),
  ];
}
