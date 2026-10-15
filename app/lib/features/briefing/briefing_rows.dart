import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/colors.dart';
import '../../core/formatters.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/day_cash.dart';
import '../../rules/haggle.dart' show marketCurrency;
import '../../rules/nearby_traps.dart';
import '../../shared/icon_tile.dart';
import '../home/home_metrics.dart';

/// One calendar stop: time on the left, the event and what its place takes.
class StopRow extends StatelessWidget {
  const StopRow({super.key, required this.stop});

  final StopCash stop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final event = stop.event;
    final place = event.matchedPlace ?? event.location!;
    final (tag, tagColor) = stop.cashOnly
        ? (l10n.briefingCashOnly, AppColors.errorText)
        : stop.cardsAccepted
        ? (l10n.briefingCardsOk, AppColors.primaryText)
        : (l10n.briefingPayUnknown, AppColors.onSurfaceTertiary);
    final last = stop.lastSpentThb;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizes.rowMinHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.groupPaddingH,
          vertical: AppSpacing.rowPaddingV,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: HomeMetrics.timeColumn,
              child: Text(
                DateFormat.Hm(locale).format(event.start),
                style: type.rowTitle.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title.trim().isEmpty ? place : event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: type.rowTitle,
                  ),
                  Text(
                    place,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: type.rowSubtitle,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(tag, style: type.label.copyWith(color: tagColor)),
                  if (last != null)
                    Text(
                      stop.lastFromSamples
                          ? l10n.briefingLastSpentSample(
                              AppFormat.roundedAmount(last, marketCurrency),
                            )
                          : l10n.briefingLastSpent(
                              AppFormat.roundedAmount(last, marketCurrency),
                            ),
                      style: type.rowSubtitle,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One trap near the traveler, with where the fact came from.
class TrapRow extends StatelessWidget {
  const TrapRow({super.key, required this.trap, this.compact = false});

  final TrapWarning trap;

  /// Inside a card of its own (Home), without the group row padding.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final (title, body) = trapText(l10n, trap);
    final where = trap.distanceM == null
        ? trap.placeName
        : l10n.briefingPlaceDistance(
            trap.placeName,
            AppFormat.roundedNumber(trap.distanceM!),
          );
    const primary = AppColors.onSurface;
    // On the pale red card tertiary grey falls below WCAG AA.
    final secondary = compact
        ? AppColors.onSurfaceSecondary
        : AppColors.onSurfaceTertiary;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: compact ? 0 : AppSizes.rowMinHeight,
      ),
      child: Padding(
        padding: compact
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(
                horizontal: AppSpacing.groupPaddingH,
                vertical: AppSpacing.rowPaddingV,
              ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            switch (trap.kind) {
              TrapKind.atmFee || TrapKind.atmConversion => const IconTile(
                icon: Icons.atm_rounded,
                light: AppColors.iconOrangeLight,
                dark: AppColors.iconOrange,
                size: AppSizes.rowIconTile,
              ),
              TrapKind.cashOnlyMarket => const IconTile(
                icon: Icons.payments_rounded,
                light: AppColors.iconYellowLight,
                dark: AppColors.iconYellow,
                size: AppSizes.rowIconTile,
              ),
            },
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: type.rowTitle.copyWith(color: primary)),
                  Text(
                    body,
                    style: type.rowSubtitle.copyWith(color: secondary),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Where first, then whose fact: a fee example is never
                  // read as this machine's own price.
                  Text(where, style: type.footer.copyWith(color: secondary)),
                  Text(
                    trapSource(l10n, trap, context),
                    style: type.footer.copyWith(color: secondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Title and body of a warning.
(String, String) trapText(AppLocalizations l10n, TrapWarning trap) =>
    switch (trap.kind) {
      TrapKind.atmFee => (
        l10n.trapAtmFeeTitle,
        trap.fee!.appliesTo == null
            ? l10n.trapAtmFeeBodyPlain(
                AppFormat.amount(trap.fee!.value, trap.fee!.currency),
              )
            : l10n.trapAtmFeeBody(
                AppFormat.amount(trap.fee!.value, trap.fee!.currency),
                trap.fee!.appliesTo!,
              ),
      ),
      TrapKind.atmConversion => (
        l10n.trapAtmConversionTitle,
        l10n.trapAtmConversionBody,
      ),
      TrapKind.cashOnlyMarket => (
        l10n.trapCashOnlyTitle,
        l10n.trapCashOnlyBody,
      ),
    };

/// "Google Maps · live", or the fee source with the day it was checked.
String trapSource(AppLocalizations l10n, TrapWarning trap, BuildContext c) {
  final checked = trap.checked;
  if (checked == null) return l10n.briefingSourceLive(trap.source);
  final locale = Localizations.localeOf(c).toLanguageTag();
  return l10n.briefingSourceChecked(
    trap.source,
    DateFormat.MMMd(locale).format(DateTime.parse(checked)),
  );
}
