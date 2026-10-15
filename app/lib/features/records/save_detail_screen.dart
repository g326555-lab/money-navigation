import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/formatters.dart';
import '../../core/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/atm_conversion.dart';
import '../../rules/exchange_rate.dart';
import '../../rules/haggle.dart' show marketCurrency;
import '../../rules/trip_ledger.dart';
import '../../shared/group.dart';
import '../scan/part_b_result_screen.dart' show rateLine;
import 'record_detail_page.dart';

/// One saved result opened from Home or Records: the figures the scan or
/// the haggle really produced, what it did to cash on hand and where.
class SaveDetailScreen extends StatelessWidget {
  const SaveDetailScreen({
    super.key,
    required this.save,
    required this.itemName,
  });

  final TripSave save;

  /// A haggle's item in the reader's language.
  final String itemName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = switch (save.kind) {
      SaveKind.atmConversion => l10n.saveAtmTitle,
      SaveKind.terminalDcc => l10n.saveTerminalTitle,
      SaveKind.haggle => l10n.saveHaggleTitle(itemName),
    };
    return RecordDetailPage(
      title: title,
      heroLabel: l10n.recordKeptHero,
      heroValue: l10n.saveKeptValue(
        AppFormat.roundedAmount(save.keptThb, marketCurrency),
      ),
      heroColor: AppColors.primaryText,
      savedAt: save.savedAt,
      isSample: save.isSample,
      children: [
        ...switch (save.kind) {
          SaveKind.atmConversion => _atm(context),
          SaveKind.terminalDcc => _terminal(context),
          SaveKind.haggle => _haggle(context),
        },
        RecordCashSection(sourceId: save.id),
        RecordPlaceSection(
          placeName: save.placeName,
          lat: save.placeLat,
          lng: save.placeLng,
        ),
      ],
    );
  }

  double? _figure(String key) => switch (save.screen?[key]) {
    final double v => v,
    _ => null,
  };

  List<Widget> _atm(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final withdrawal = _figure(AtmFigures.withdrawalThb);
    final fee = _figure(AtmFigures.accessFeeThb);
    final rate = _figure(AtmFigures.thbPerUsd);
    final markup = _figure(AtmFigures.markupPercent);
    final chargedThb = _figure(AtmFigures.chargedThb);
    final chargedUsd = _figure(AtmFigures.chargedUsd);
    if ([withdrawal, fee, rate, chargedThb, chargedUsd].contains(null)) {
      return [_noFigures(context)];
    }
    return [
      SectionHeader(l10n.atmBothTotals, first: true),
      GroupCard(
        children: [
          GroupRow(
            title: l10n.atmIfConvert,
            subtitle: l10n.atmIfConvertDetail,
            value: AppFormat.cents(chargedUsd!, atmCardCurrency),
          ),
          GroupRow(
            title: l10n.atmIfNotConvert,
            subtitle: l10n.atmIfNotConvertDetail,
            value: AppFormat.amount(chargedThb!, atmLocalCurrency),
            valueStyle: type.rowTitle.copyWith(color: AppColors.primaryText),
          ),
        ],
      ),
      SectionHeader(l10n.atmOnScreen),
      GroupCard(
        children: [
          GroupRow(
            title: l10n.atmRowWithdrawal,
            value: AppFormat.amount(withdrawal!, atmLocalCurrency),
          ),
          GroupRow(
            title: l10n.atmRowFee,
            value: AppFormat.amount(fee!, atmLocalCurrency),
          ),
          GroupRow(
            title: l10n.atmRowRate,
            value: l10n.atmRateValue(AppFormat.rate(rate!)),
          ),
          if (markup != null)
            GroupRow(
              title: l10n.atmRowMarkup,
              value: AppFormat.percent(markup),
            ),
        ],
      ),
    ];
  }

  List<Widget> _terminal(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final screen = save.screen;
    final homeCode = screen?[TerminalFigures.homeCode];
    final localCode = screen?[TerminalFigures.localCode];
    final homeKey = screen?[TerminalFigures.homeKey];
    final localKey = screen?[TerminalFigures.localKey];
    final rateDate = screen?[TerminalFigures.rateDate];
    final homeAmount = _figure(TerminalFigures.homeAmount);
    final localAmount = _figure(TerminalFigures.localAmount);
    final fair = _figure(TerminalFigures.fairHomeAmount);
    final rate = _figure(TerminalFigures.rate);
    if (homeCode is! String ||
        localCode is! String ||
        homeKey is! String ||
        localKey is! String ||
        rateDate is! String ||
        [homeAmount, localAmount, fair, rate].contains(null)) {
      return [_noFigures(context)];
    }
    final quote = RateQuote(
      base: homeCode,
      quote: localCode,
      rate: rate!,
      date: rateDate,
      fetchedAt: save.savedAt,
    );
    return [
      SectionHeader(l10n.dccBothOptions, first: true),
      GroupCard(
        children: [
          GroupRow(
            title: homeKey,
            subtitle: l10n.dccOptionHomeMore(
              AppFormat.roundedAmount(save.keptThb, homeCode),
            ),
            value: AppFormat.amount(homeAmount!, homeCode),
          ),
          GroupRow(
            title: localKey,
            subtitle: l10n.dccOptionLocal,
            value: AppFormat.amount(localAmount!, localCode),
            valueStyle: type.rowTitle.copyWith(color: AppColors.primaryText),
          ),
          GroupRow(
            title: l10n.dccFairHome(homeCode),
            value: AppFormat.amount(fair!, homeCode),
          ),
        ],
      ),
      GroupFooter(
        rateLine(
          context,
          l10n,
          quote,
          demo: screen?[TerminalFigures.rateSource] == 'demo',
        ),
      ),
    ];
  }

  List<Widget> _haggle(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    String amounts(List<double> list) =>
        list.map((p) => AppFormat.roundedAmount(p, marketCurrency)).join(' → ');
    final sellers = save.sellerPrices;
    final offers = save.ourOffers;
    return [
      SectionHeader(l10n.recordChecks, first: true),
      GroupCard(
        children: [
          GroupRow(title: l10n.recordItem, value: itemName),
          if (save.askedThb != null)
            GroupRow(
              title: l10n.saveDetailsAsked,
              value: AppFormat.amount(save.askedThb!, marketCurrency),
            ),
          if (save.paidThb != null)
            GroupRow(
              title: l10n.saveDetailsPaid,
              value: AppFormat.amount(save.paidThb!, marketCurrency),
              valueStyle: type.rowTitle.copyWith(color: AppColors.primaryText),
            ),
          if (sellers != null && sellers.isNotEmpty)
            GroupRow(
              title: l10n.recordSellerPrices,
              subtitle: amounts(sellers),
            ),
          if (offers != null && offers.isNotEmpty)
            GroupRow(title: l10n.recordYourOffers, subtitle: amounts(offers)),
        ],
      ),
    ];
  }

  Widget _noFigures(BuildContext context) =>
      GroupFooter(AppLocalizations.of(context).recordNoFigures);
}
