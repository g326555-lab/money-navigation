import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/colors.dart';
import '../../core/elevation.dart';
import '../../core/formatters.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/day_cash.dart';
import '../../rules/haggle.dart' show marketCurrency;
import '../../shared/icon_tile.dart';
import '../../shared/pressable.dart';
import '../../shared/surface.dart';
import '../assistant/assistant_screen.dart' show cashBasis;
import 'home_metrics.dart';

/// "Route preview": today's cash and the day's stops as a small timetable.
class BriefingCard extends StatelessWidget {
  const BriefingCard({
    super.key,
    required this.plan,
    required this.calendarConnected,
    required this.onConnect,
    required this.onOpen,
  });

  final DayCashPlan? plan;
  final bool calendarConnected;
  final VoidCallback onConnect;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final amount = plan?.amountThb;
    final stops = plan?.stops ?? const <StopCash>[];
    return Pressable(
      onPressed: onOpen,
      semanticLabel: l10n.homeBriefingOpen,
      child: Surface(
        radius: AppRadius.xl,
        color: AppColors.surface,
        shadows: AppElevation.e0,
        // The link row brings its own 48 of height at the bottom.
        padding: EdgeInsets.fromLTRB(
          AppSpacing.cardPadding,
          AppSpacing.cardPadding,
          AppSpacing.cardPadding,
          calendarConnected ? AppSpacing.cardPadding : AppSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const IconTile(
                  icon: Icons.wb_twilight_rounded,
                  light: AppColors.iconYellowLight,
                  dark: AppColors.iconYellow,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    l10n.homeToday,
                    style: type.label.copyWith(
                      color: AppColors.onSurfaceSecondary,
                    ),
                  ),
                ),
                Text(
                  DateFormat.MMMEd(locale).format(DateTime.now()),
                  style: type.label.copyWith(
                    color: AppColors.onSurfaceTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              amount == null
                  ? (stops.isEmpty
                        ? l10n.homeBriefingNoNumber
                        : l10n.homeBriefingStops(stops.length))
                  : l10n.homeCashToday(
                      AppFormat.roundedAmount(amount, marketCurrency),
                    ),
              // The figure is the headline; without one the line stays quiet.
              style: amount == null ? type.rowTitle : type.title,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(cashBasis(l10n, plan), style: type.footer),
            if (stops.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              for (final s in stops.take(HomeMetrics.homeEvents))
                _StopLine(stop: s, locale: locale),
              if (stops.length > HomeMetrics.homeEvents)
                Text(
                  l10n.homeBriefingMore(stops.length - HomeMetrics.homeEvents),
                  style: type.footer,
                ),
            ],
            if (!calendarConnected) ...[
              const SizedBox(height: AppSpacing.sm),
              Pressable(
                onPressed: onConnect,
                semanticLabel: l10n.calendarConnect,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppSizes.minTouchTarget,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.event_rounded,
                        size: AppSizes.pillIcon,
                        color: AppColors.onSurfaceTertiary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(l10n.calendarConnect, style: type.link),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StopLine extends StatelessWidget {
  const _StopLine({required this.stop, required this.locale});

  final StopCash stop;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final e = stop.event;
    final (tag, color) = stop.cashOnly
        ? (l10n.briefingCashOnly, AppColors.errorText)
        : stop.cardsAccepted
        ? (l10n.briefingCardsOk, AppColors.primaryText)
        : (null, null);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          SizedBox(
            width: HomeMetrics.timeColumn,
            child: Text(
              DateFormat.Hm(locale).format(e.start),
              style: type.label.copyWith(
                color: AppColors.onSurfaceTertiary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            child: Text(
              e.title.trim().isEmpty
                  ? (e.matchedPlace ?? e.location!)
                  : e.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: type.label.copyWith(color: AppColors.onSurface),
            ),
          ),
          if (tag != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(tag, style: type.label.copyWith(color: color)),
          ],
        ],
      ),
    );
  }
}
