import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/colors.dart';
import '../../core/elevation.dart';
import '../../core/formatters.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/haggle.dart' show marketCurrency;
import '../../rules/pay_route.dart';
import '../../rules/personal_context.dart';
import '../../shared/surface.dart';
import '../briefing/trip_context.dart';

/// "Card, cash or QR": the traveler types an amount, the card shows which
/// way adds the least, from their card fee and the sourced ATM fee.
class PayCompareCard extends StatefulWidget {
  const PayCompareCard({
    super.key,
    required this.trip,
    required this.profile,
    required this.withdrawalThb,
    required this.place,
    required this.onEditCard,
  });

  final TripContext trip;
  final TravelerProfile profile;

  /// Today's planned cash, used as one withdrawal; null when unknown.
  final double? withdrawalThb;

  /// The stop the comparison is for, when one was chosen.
  final PlacePayment place;
  final VoidCallback onEditCard;

  @override
  State<PayCompareCard> createState() => _PayCompareCardState();
}

class _PayCompareCardState extends State<PayCompareCard> {
  final _amount = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amount.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  double? get _typed {
    final v = double.tryParse(_amount.text.replaceAll(',', '').trim());
    return v == null || v <= 0 ? null : v;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final trip = widget.trip;
    final amount = _typed;
    final rate = trip.localToThb;
    final route = amount == null || rate == null
        ? null
        : payRoute(
            amountLocal: amount,
            localToThb: rate,
            place: widget.place,
            profile: widget.profile,
            facts: trip.localFacts,
            withdrawalThb: widget.withdrawalThb,
            homeToThb: trip.homeToThb,
          );

    return Surface(
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.surfaceDarkTop, AppColors.surfaceDark],
      ),
      shadows: AppElevation.e1,
      edgeLight: EdgeLights.onDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.payCompareLabel,
            style: type.label.copyWith(color: AppColors.primaryOnDark),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _verdict(l10n, route),
            style: type.title.copyWith(color: AppColors.onSurfaceDark),
          ),
          const SizedBox(height: AppSpacing.lg),
          _AmountField(
            controller: _amount,
            currency: trip.localCurrency,
            hint: l10n.payCompareAmountHint,
          ),
          if (rate == null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.payCompareNoRate(trip.localCurrency),
              style: type.rowSubtitle.copyWith(
                color: AppColors.onSurfaceDarkSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          for (final method in PayMethod.values)
            _OptionLine(
              method: method,
              option: route?.option(method),
              best: route?.best == method,
              cardFeeKnown: widget.profile.cardFeePercent != null,
              onEditCard: widget.onEditCard,
            ),
          if (route?.breakEvenWithdrawalThb case final b? when b > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.payCompareBreakEven(
                AppFormat.roundedAmount(b, marketCurrency),
              ),
              style: type.rowSubtitle.copyWith(
                color: AppColors.onSurfaceDarkSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            _basis(l10n, trip),
            style: type.footer.copyWith(
              color: AppColors.onSurfaceDarkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _verdict(AppLocalizations l10n, PayRoute? route) {
    if (route == null) return l10n.payCompareAsk;
    if (route.forcedByPlace) return l10n.payCompareCashOnly;
    if (route.sameCost) return l10n.payCompareSame;
    return switch (route.best) {
      PayMethod.card => l10n.payCompareBestCard,
      PayMethod.cash => l10n.payCompareBestCash,
      PayMethod.qr => l10n.payCompareBestQr,
      null =>
        widget.profile.cardFeePercent == null
            ? l10n.payCompareNeedCard
            : l10n.payCompareNeedWithdrawal,
    };
  }

  String _basis(AppLocalizations l10n, TripContext trip) {
    final fee = trip.localFacts?.foreignCardAtmFee;
    final atm = fee == null
        ? l10n.payCompareNoAtmFee
        : l10n.payCompareAtmFeeSource(
            AppFormat.amount(fee.value, fee.currency),
            fee.source,
          );
    return trip.rateIsDemo ? '$atm · ${l10n.payCompareDemoRate}' : atm;
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.currency,
    required this.hint,
  });

  final TextEditingController controller;
  final String currency;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final type = AppTypography.of(context);
    return Surface(
      radius: AppRadius.md,
      color: AppColors.stackCard,
      shadows: const [],
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              cursorColor: AppColors.primaryOnDark,
              style: type.headline.copyWith(
                color: AppColors.onSurfaceDark,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: type.bodyLg.copyWith(
                  color: AppColors.onSurfaceDarkSecondary,
                ),
              ),
            ),
          ),
          Text(
            currency,
            style: type.bodyLg.copyWith(
              color: AppColors.onSurfaceDarkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionLine extends StatelessWidget {
  const _OptionLine({
    required this.method,
    required this.option,
    required this.best,
    required this.cardFeeKnown,
    required this.onEditCard,
  });

  final PayMethod method;
  final PayOption? option;
  final bool best;
  final bool cardFeeKnown;
  final VoidCallback onEditCard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final name = switch (method) {
      PayMethod.card => l10n.payCard,
      PayMethod.cash => l10n.payCash,
      PayMethod.qr => l10n.payQr,
    };
    final o = option;
    final String value;
    if (o == null) {
      value = '';
    } else if (o.accepted == Acceptance.no) {
      value = l10n.payNotTaken;
    } else if (o.extraThb != null) {
      value = l10n.payExtra(AppFormat.cents(o.extraThb!, marketCurrency));
    } else {
      value = switch (method) {
        PayMethod.card => l10n.payNeedCardFee,
        PayMethod.cash => l10n.payNeedWithdrawal,
        PayMethod.qr => l10n.payNoQrFee,
      };
    }
    final color = best ? AppColors.primaryOnDark : AppColors.onSurfaceDark;
    final line = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            switch (method) {
              PayMethod.card => Icons.credit_card_rounded,
              PayMethod.cash => Icons.payments_rounded,
              PayMethod.qr => Icons.qr_code_rounded,
            },
            size: AppSizes.pillIcon,
            color: color,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(name, style: type.bodyLg.copyWith(color: color)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: type.rowSubtitle.copyWith(
                color: best ? color : AppColors.onSurfaceDarkSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
    if (method == PayMethod.card && !cardFeeKnown) {
      return Semantics(
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onEditCard,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSizes.minTouchTarget,
            ),
            child: Align(alignment: Alignment.centerLeft, child: line),
          ),
        ),
      );
    }
    return line;
  }
}
