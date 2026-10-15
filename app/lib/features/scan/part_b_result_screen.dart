import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../app/app_scope.dart';
import '../../core/colors.dart';
import '../../core/formatters.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/exchange_board.dart';
import '../../rules/exchange_rate.dart';
import '../../rules/terminal_dcc.dart';
import '../../rules/trip_ledger.dart';
import '../../shared/action_dock.dart';
import '../../shared/app_button.dart';
import '../../shared/content_width.dart';
import '../../shared/group.dart';
import '../../shared/pill.dart';
import 'atm_result_screen.dart';
import 'scan_controller.dart';

/// The traveler's home currency in Part B (Thai travelers abroad).
const partBHomeCurrency = 'THB';

/// Verdict for a card terminal that offers to charge in the traveler's home
/// currency: which key to press and how much paying locally keeps.
class DccResultScreen extends StatelessWidget {
  const DccResultScreen({super.key, required this.state, required this.demo});

  final ScanState state;

  /// True when the rate is the fixed demo rate, not a live one.
  final bool demo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final v = state.dcc!;
    final local = v.localOption.code ?? v.rate.quote;
    final details = _details(context, l10n, v);
    if (!v.payLocal || v.extraHome.round() <= 0) {
      return _PlainResult(
        title: l10n.dccEvenTitle,
        body: l10n.dccEvenBody,
        details: details,
      );
    }
    return SuccessView(
      hero: SuccessHero(
        label: l10n.dccKeepLabel(local),
        amount: v.extraHome,
        unit: partBHomeCurrency,
        // The markup is derived from our rate, so it is an estimate.
        chip: l10n.dccMarkupChip(AppFormat.roundedPercent(v.markupPercent)),
      ),
      press: PressCard(
        label: l10n.atmPress,
        action: l10n.dccPressKey(v.localOption.key, local),
        reason: l10n.dccReason(
          partBHomeCurrency,
          AppFormat.roundedPercent(v.markupPercent),
        ),
      ),
      details: details,
      closeLabel: l10n.scanClose,
      actionLabel: l10n.atmScanAnother,
      saveLabel: l10n.saveToTrip,
      onSave: () => _save(context),
    );
  }

  Future<void> _save(BuildContext context) async {
    final trip = AppScope.of(context).trip;
    final navigator = Navigator.of(context);
    final save = saveFromDcc(
      state.dcc!,
      id: 'dcc-${state.scannedAt!.microsecondsSinceEpoch}',
      savedAt: DateTime.now(),
      demoRate: demo,
    );
    if (save == null) return;
    if (!trip.contains(save.id)) await trip.add(save);
    HapticFeedback.mediumImpact();
    navigator.popUntil((route) => route.isFirst);
  }

  List<Widget> _details(
    BuildContext context,
    AppLocalizations l10n,
    DccVerdict v,
  ) {
    final type = AppTypography.of(context);
    String option(TerminalOption o) => AppFormat.amount(o.amount, o.code ?? '');
    // Same pattern as the ATM verdict: the key to press is green, and the
    // dearer key says in words what it costs, never by color alone.
    final dearer = v.payLocal && v.extraHome.round() > 0;
    return [
      SectionHeader(l10n.dccBothOptions, first: true),
      GroupCard(
        children: [
          GroupRow(
            title: l10n.dccOptionKey(v.homeOption.key),
            subtitle: dearer
                ? l10n.dccOptionHomeMore(
                    AppFormat.roundedAmount(v.extraHome, partBHomeCurrency),
                  )
                : l10n.dccOptionHome,
            value: option(v.homeOption),
          ),
          GroupRow(
            title: l10n.dccOptionKey(v.localOption.key),
            subtitle: l10n.dccOptionLocal,
            value: option(v.localOption),
            valueStyle: dearer
                ? type.rowTitle.copyWith(color: AppColors.primaryText)
                : null,
          ),
          GroupRow(
            title: l10n.dccFairHome(partBHomeCurrency),
            value: AppFormat.amount(v.fairHomeAmount, partBHomeCurrency),
          ),
        ],
      ),
      GroupFooter(rateLine(context, l10n, v.rate, demo: demo)),
    ];
  }
}

/// A money changer's board: how much less than the middle rate the
/// traveler gets when selling their currency here.
class BoardResultScreen extends StatelessWidget {
  const BoardResultScreen({super.key, required this.state, required this.demo});

  final ScanState state;

  /// True when the reference rate is the fixed demo rate, not a live one.
  final bool demo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final b = state.board!;
    final reference = state.boardReference;
    final vsReference = reference == null
        ? null
        : lossVsReferencePercent(b, reference, home: partBHomeCurrency);
    return _PlainResult(
      hero: _BoardHero(
        label: l10n.boardHeroLabel(b.code),
        percent: AppFormat.roundedPercent(b.sellLossPercent),
        chip: l10n.boardLossChip(
          AppFormat.cents(b.lossWhenSelling(100), partBHomeCurrency),
          AppFormat.amount(100, b.code),
        ),
      ),
      details: [
        SectionHeader(l10n.boardRates(b.code), first: true),
        GroupCard(
          children: [
            GroupRow(
              title: l10n.boardBuying,
              subtitle: l10n.boardBuyingHint(b.code),
              value: AppFormat.preciseRate(b.buying),
            ),
            GroupRow(
              title: l10n.boardSelling,
              value: AppFormat.preciseRate(b.selling),
            ),
            GroupRow(
              title: l10n.boardMid,
              value: AppFormat.preciseRate(b.mid),
              valueStyle: type.rowTitle.copyWith(color: AppColors.primaryText),
            ),
          ],
        ),
        GroupFooter(l10n.boardSource),
        if (reference != null && vsReference != null)
          GroupFooter(
            // An older board can buy above today's rate; say so plainly
            // rather than "-4.3 % below".
            (vsReference < 0
                ? l10n.boardAboveReference
                : l10n.boardVsReference)(
              AppFormat.roundedPercent(vsReference.abs()),
              rateLine(context, l10n, reference, demo: demo),
            ),
          ),
      ],
    );
  }
}

/// Hero zone for the board: what selling here means, the percent as the
/// largest figure, and the chip in money.
class _BoardHero extends StatelessWidget {
  const _BoardHero({
    required this.label,
    required this.percent,
    required this.chip,
  });

  final String label;
  final String percent;
  final String chip;

  @override
  Widget build(BuildContext context) {
    final type = AppTypography.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: type.heroLabel),
        const SizedBox(height: AppSpacing.sm),
        Text(percent, style: type.displayLg),
        const SizedBox(height: AppSpacing.md),
        Pill(
          label: chip,
          fill: AppColors.errorContainer,
          textColor: AppColors.errorText,
        ),
      ],
    );
  }
}

/// "1 THB = 4.6935 JPY · fixed demo rate, 15 Oct" or the live source.
String rateLine(
  BuildContext context,
  AppLocalizations l10n,
  RateQuote rate, {
  required bool demo,
}) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final date = DateFormat.MMMd(locale).format(DateTime.parse(rate.date));
  final pair = rate.rate >= 1
      // A stated rate keeps every digit (4.6935); an inverted one is rounded.
      ? l10n.ratePair(rate.base, AppFormat.preciseRate(rate.rate), rate.quote)
      : l10n.ratePair(
          rate.quote,
          AppFormat.rateValue(inverseRate(rate)),
          rate.base,
        );
  return demo
      ? l10n.rateDemoSource(pair, date)
      : l10n.homeRateSource(pair, date);
}

/// A result with nothing kept: a hero zone (a title and explanation, or a
/// figure), details, one action.
class _PlainResult extends StatelessWidget {
  const _PlainResult({this.title, this.body, this.hero, required this.details})
    : assert((title != null && body != null) || hero != null);

  final String? title;
  final String? body;
  final Widget? hero;
  final List<Widget> details;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: ContentWidth(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenMargin,
                    0,
                    AppSpacing.screenMargin,
                    AppSpacing.zoneGap + ActionDock.heightOf(context),
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      // The glyph, not its touch area, lines up with the text.
                      child: Transform.translate(
                        offset: const Offset(
                          -(AppSizes.minTouchTarget - AppSizes.tabIcon) / 2,
                          0,
                        ),
                        child: IconButton(
                          tooltip: l10n.scanClose,
                          icon: const Icon(Icons.close_rounded),
                          color: AppColors.onSurface,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ?hero,
                    if (hero == null) ...[
                      Text(title!, style: type.headline),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        body!,
                        style: type.bodyMd.copyWith(
                          color: AppColors.onSurfaceSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.zoneGap),
                    ...details,
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ActionDock(
                child: AppButton(
                  label: l10n.atmScanAnother,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
