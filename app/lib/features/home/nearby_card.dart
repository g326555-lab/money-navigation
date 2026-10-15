import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/elevation.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/nearby_traps.dart';
import '../../shared/icon_tile.dart';
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
    if (state == NearbyState.noLocation) {
      return Pressable(
        onPressed: onAskLocation,
        semanticLabel: l10n.nearbyNeedLocation,
        child: Surface(
          radius: AppRadius.lg,
          color: AppColors.surface,
          shadows: AppElevation.e0,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              const IconTile.blue(icon: Icons.near_me_rounded),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.nearbyNeedLocation, style: type.rowTitle),
                    Text(l10n.nearbyLocationPrivacy, style: type.rowSubtitle),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (state != NearbyState.done || traps.isEmpty) {
      return const SizedBox.shrink();
    }
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
