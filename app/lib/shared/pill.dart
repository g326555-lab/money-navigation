import 'package:flutter/widgets.dart';

import '../core/colors.dart';
import '../core/spacing.dart';
import '../core/typography.dart';

/// A capsule label: the one chip under a hero number, or a verdict chip.
/// Radius is half the height (Apple's capsule), so it is concentric with
/// nothing and never needs a superellipse.
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    required this.fill,
    required this.textColor,
    this.shadows = const [],
  });

  /// A white pill on a green surface, its shadow tinted green.
  const Pill.onGreen({super.key, required this.label, this.shadows = const []})
    : fill = AppColors.surface,
      textColor = AppColors.onPrimaryContainer;

  final String label;
  final Color fill;
  final Color textColor;
  final List<BoxShadow> shadows;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        color: fill,
        shadows: shadows,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.chipPadding,
        ),
        child: Text(
          label,
          style: AppTypography.of(context).label.copyWith(color: textColor),
        ),
      ),
    );
  }
}
