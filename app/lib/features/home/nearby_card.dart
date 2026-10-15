import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/elevation.dart';
import '../../core/motion.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/nearby_traps.dart';
import '../../shared/pressable.dart';
import '../../shared/surface.dart';
import '../briefing/briefing_controller.dart';
import '../briefing/briefing_rows.dart';

/// "Speed camera" on Home: the most important trap near the phone, on a
/// pale red card, or a prompt to look when location is off.
class NearbyCard extends StatelessWidget {
  const NearbyCard({
    super.key,
    required this.state,
    required this.traps,
    required this.onAskLocation,
    required this.onOpen,
  });

  final NearbyState state;
  final List<TrapWarning> traps;
  final VoidCallback onAskLocation;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    // The gap above lives here, so nothing is left behind while hidden.
    final Widget? shown;
    if (state == NearbyState.noLocation) {
      // A quiet link, not another card: Home keeps one shape per job.
      shown = Pressable(
        onPressed: onAskLocation,
        semanticLabel: l10n.nearbyNeedLocation,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
          child: Row(
            children: [
              const Icon(
                Icons.near_me_rounded,
                size: AppSizes.pillIcon,
                color: AppColors.onSurfaceTertiary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(l10n.nearbyNeedLocation, style: type.link)),
            ],
          ),
        ),
      );
    } else if (state == NearbyState.done && traps.isNotEmpty) {
      shown = _warning(context);
    } else {
      shown = null;
    }
    return AnimatedSize(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppMotion.standard,
      curve: AppMotion.enter,
      alignment: Alignment.topCenter,
      child: shown == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: AppSpacing.groupGap),
              child: shown,
            ),
    );
  }

  Widget _warning(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final more = traps.length - 1;
    return Pressable(
      onPressed: onOpen,
      semanticLabel: l10n.nearbyOpen,
      child: Surface(
        radius: AppRadius.xl,
        color: AppColors.errorContainer,
        shadows: AppElevation.e1,
        pressedShadows: AppElevation.e0,
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.nearbyLabel,
              style: type.label.copyWith(color: AppColors.errorText),
            ),
            const SizedBox(height: AppSpacing.md),
            TrapRow(trap: traps.first, compact: true),
            if (more > 0) ...[
              const SizedBox(height: AppSpacing.md),
              Text(l10n.nearbyMore(more), style: type.link),
            ],
          ],
        ),
      ),
    );
  }
}
