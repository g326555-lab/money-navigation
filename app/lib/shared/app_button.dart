import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/colors.dart';
import '../core/elevation.dart';
import '../core/spacing.dart';
import '../core/typography.dart';
import 'pressable.dart';
import 'surface.dart';

/// Which of the three button looks (DESIGN.md "Components").
enum AppButtonKind {
  /// Dark, lit from above: the one action to take on a screen.
  primary,

  /// Light grey, flat on the page: the alternative beside the primary.
  secondary,

  /// Green, lit from above: an action that speaks or confirms money kept,
  /// used on the dark card.
  green,
}

/// The app's button: a superellipse [Surface] with a top-lit gradient, a
/// light edge and E1 shadow (primary and green), which sinks into the page
/// while pressed and springs back. Labels shrink to fit rather than clip,
/// so a two-word label always reads whole at the Fold cover width.
///
/// Disabled ([onPressed] null) drops to a flat grey with muted text and no
/// shadow, so it never looks tappable; the label stays where it was.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = AppButtonKind.primary,
    this.icon,
    this.busy = false,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
  }) : kind = AppButtonKind.secondary;

  const AppButton.green({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
  }) : kind = AppButtonKind.green;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonKind kind;
  final IconData? icon;

  /// Working on what was asked (e.g. speaking): keeps the enabled look and
  /// its label, but ignores taps until done.
  final bool busy;

  static const _darkFill = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.surfaceDarkTop, AppColors.surfaceDark],
  );

  static const _greenFill = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.primaryTop, AppColors.primaryBottom],
  );

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null || busy;
    final (
      Gradient? gradient,
      Color? fill,
      Color text,
      shadows,
      edge,
    ) = !enabled
        ? (
            null,
            AppColors.surfaceDim,
            AppColors.onSurfaceMuted,
            const <BoxShadow>[],
            null,
          )
        : switch (kind) {
            AppButtonKind.primary => (
              _darkFill,
              null,
              AppColors.onSurfaceDark,
              AppElevation.e1,
              EdgeLights.onDark,
            ),
            AppButtonKind.secondary => (
              null,
              AppColors.surfaceDim,
              AppColors.onSurface,
              const <BoxShadow>[],
              null,
            ),
            AppButtonKind.green => (
              _greenFill,
              null,
              AppColors.onPrimary,
              AppElevation.e1GreenButton,
              EdgeLights.onGreen,
            ),
          };
    final style = AppTypography.of(context).bodyLg.copyWith(color: text);
    return Pressable(
      onPressed: busy ? null : onPressed,
      semanticLabel: label,
      // A primary tap commits something; the secondary only switches view.
      haptic: kind == AppButtonKind.secondary
          ? HapticFeedback.selectionClick
          : HapticFeedback.lightImpact,
      child: Surface(
        radius: AppRadius.md,
        gradient: gradient,
        color: fill,
        shadows: shadows,
        edgeLight: edge,
        child: SizedBox(
          height: AppSizes.buttonHeight,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.buttonPaddingH,
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: AppSizes.buttonIcon, color: text),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Text(label, maxLines: 1, style: style),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
