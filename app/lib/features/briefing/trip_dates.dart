import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/colors.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/trip_period.dart';
import '../../shared/group.dart';
import '../../shared/icon_tile.dart';
import '../../shared/pill.dart';
import '../../shared/pressable.dart';
import 'briefing_controller.dart';

/// Asks for the trip's first and last day with the system date-range
/// picker and saves them. Returns true when dates were saved.
Future<bool> askTripDates(
  BuildContext context,
  BriefingController briefing,
) async {
  final l10n = AppLocalizations.of(context);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final current = briefing.trip.period;
  final picked = await showDateRangePicker(
    context: context,
    firstDate: DateTime(today.year - 1, today.month, today.day),
    lastDate: DateTime(today.year + 1, today.month, today.day),
    initialDateRange: current == null
        ? null
        : DateTimeRange(start: current.start, end: current.end),
    currentDate: today,
    helpText: l10n.tripDatesPickerTitle,
    saveText: l10n.tripDatesSave,
  );
  if (picked == null || !context.mounted) return false;
  final period = tripPeriodOrNull(picked.start, picked.end);
  if (period == null) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l10n.tripDatesTooLong(maxTripDays))),
      );
    return false;
  }
  HapticFeedback.selectionClick();
  await briefing.setTripPeriod(period);
  return true;
}

/// "When is your trip?" before any dates are set.
class TripDatesPrompt extends StatelessWidget {
  const TripDatesPrompt({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GroupCard(
      children: [
        Pressable(
          onPressed: onPressed,
          semanticLabel: l10n.tripDatesAsk,
          child: Row(
            children: [
              Expanded(
                child: GroupRow(
                  leading: const IconTile.blue(
                    icon: Icons.date_range_rounded,
                  ),
                  title: l10n.tripDatesAsk,
                  subtitle: l10n.tripDatesAskBody,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: AppSpacing.lg),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.onSurfaceMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Day 4 of 5" with one chip per trip day; the chosen day's stops show
/// below it. [onChange] edits the dates (null for the demo's fixed trip).
class TripDayStrip extends StatelessWidget {
  const TripDayStrip({
    super.key,
    required this.period,
    required this.day,
    required this.onDay,
    this.onChange,
    this.sample = false,
  });

  final TripPeriod period;
  final DateTime day;
  final ValueChanged<DateTime> onDay;
  final VoidCallback? onChange;
  final bool sample;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final range =
        '${DateFormat.MMMd(locale).format(period.start)} – '
        '${DateFormat.MMMd(locale).format(period.end)}';
    final number = period.dayNumber(day);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sectionHeaderInset,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  [
                    if (number != null) l10n.tripDayOf(number, period.length),
                    sample ? l10n.tripDatesSample : l10n.tripDatesRange(range),
                  ].join(' · '),
                  style: type.label.copyWith(
                    color: AppColors.onSurfaceSecondary,
                  ),
                ),
              ),
              if (onChange != null)
                Pressable(
                  onPressed: onChange!,
                  semanticLabel: l10n.tripDatesChange,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: AppSizes.minTouchTarget,
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        l10n.tripDatesChange,
                        style: type.link.copyWith(
                          color: AppColors.primaryText,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final d in period.days) ...[
                Pressable(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onDay(d);
                  },
                  semanticLabel: l10n.tripStopsOn(
                    DateFormat.MMMEd(locale).format(d),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: AppSizes.minTouchTarget,
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: Pill(
                        label: d == today
                            ? l10n.tripMapToday
                            : DateFormat.MMMEd(locale).format(d),
                        fill: d == day
                            ? AppColors.surfaceDark
                            : AppColors.surface,
                        textColor: d == day
                            ? AppColors.onSurfaceDark
                            : AppColors.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}
