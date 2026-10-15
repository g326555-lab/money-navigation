import 'package:flutter/painting.dart';

import 'colors.dart';

/// The only two shadow levels (DESIGN.md "Elevation & Depth").
abstract final class AppElevation {
  /// Hero card and the dark action card.
  static final e1 = [
    BoxShadow(
      color: AppColors.shadow.withValues(alpha: 0.04),
      offset: const Offset(0, 1),
      blurRadius: 2,
    ),
    BoxShadow(
      color: AppColors.shadow.withValues(alpha: 0.05),
      offset: const Offset(0, 4),
      blurRadius: 12,
    ),
  ];

  /// Floating chrome: tab bar and action dock.
  static final e2 = [
    BoxShadow(
      color: AppColors.shadow.withValues(alpha: 0.06),
      offset: const Offset(0, 2),
      blurRadius: 6,
    ),
    BoxShadow(
      color: AppColors.shadow.withValues(alpha: 0.12),
      offset: const Offset(0, 10),
      blurRadius: 30,
    ),
  ];

  /// E2 cast upwards, for bottom sheets.
  static final e2Sheet = [
    for (final s in e2)
      BoxShadow(
        color: s.color,
        offset: Offset(0, -s.offset.dy - 6),
        blurRadius: s.blurRadius,
      ),
  ];
}
