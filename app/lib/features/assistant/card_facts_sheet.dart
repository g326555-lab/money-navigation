import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/colors.dart';
import '../../core/elevation.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/personal_context.dart';
import '../../shared/app_button.dart';
import '../../shared/pressable.dart';
import '../../shared/surface.dart';
import '../home/home_metrics.dart';
import 'card_profile_store.dart';

/// Edits the card's foreign fee and the home bank's ATM fee.
Future<void> showCardFactsSheet(
  BuildContext context,
  CardProfileStore store,
  String homeCurrency,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => _CardFactsSheet(store: store, homeCurrency: homeCurrency),
);

class _CardFactsSheet extends StatefulWidget {
  const _CardFactsSheet({required this.store, required this.homeCurrency});

  final CardProfileStore store;
  final String homeCurrency;

  @override
  State<_CardFactsSheet> createState() => _CardFactsSheetState();
}

class _CardFactsSheetState extends State<_CardFactsSheet> {
  late final _fee = TextEditingController(
    text: _plain(widget.store.profile.cardFeePercent),
  );
  late final _atmValue = TextEditingController(
    text: _plain(widget.store.profile.atmFeeValue),
  );
  late AtmFeePolicy _policy = widget.store.profile.atmFeePolicy;
  String? _error;

  static String _plain(double? v) => v == null
      ? ''
      : (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString());

  @override
  void dispose() {
    _fee.dispose();
    _atmValue.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final feeText = _fee.text.replaceAll(',', '.').trim();
    final fee = feeText.isEmpty ? null : double.tryParse(feeText);
    if (feeText.isNotEmpty &&
        (fee == null || fee < 0 || fee > CardProfileStore.maxFeePercent)) {
      setState(() => _error = l10n.cardFeeInvalid);
      return;
    }
    final needsValue =
        _policy == AtmFeePolicy.chargesFixed ||
        _policy == AtmFeePolicy.chargesPercent;
    final value = double.tryParse(_atmValue.text.replaceAll(',', '.').trim());
    if (needsValue && (value == null || value < 0)) {
      setState(() => _error = l10n.cardAtmValueInvalid);
      return;
    }
    await widget.store.setCardFee(fee);
    await widget.store.setAtmPolicy(_policy, value: needsValue ? value : null);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final policies = {
      AtmFeePolicy.unknown: l10n.cardAtmUnknown,
      AtmFeePolicy.noFee: l10n.cardAtmNoFee,
      AtmFeePolicy.refundsFees: l10n.cardAtmRefunds,
      AtmFeePolicy.chargesFixed: l10n.cardAtmFixed(widget.homeCurrency),
      AtmFeePolicy.chargesPercent: l10n.cardAtmPercent,
    };
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: Surface(
        radius: AppRadius.sheet,
        color: AppColors.surface,
        shadows: AppElevation.e2Sheet,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sheetPadding,
          AppSpacing.md,
          AppSpacing.sheetPadding,
          AppSpacing.sheetPadding,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Grabber(),
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.cardSheetTitle, style: type.title),
                const SizedBox(height: AppSpacing.xl),
                Text(l10n.cardFeeLabel, style: type.rowTitle),
                const SizedBox(height: AppSpacing.sm),
                _Field(controller: _fee, suffix: '%'),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.homeCurrency == 'THB'
                      ? l10n.cardFeeHintThai
                      : l10n.cardFeeHintOther,
                  style: type.footer,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(l10n.cardAtmLabel, style: type.rowTitle),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final e in policies.entries)
                      _Choice(
                        label: e.value,
                        selected: _policy == e.key,
                        onPressed: () => setState(() => _policy = e.key),
                      ),
                  ],
                ),
                if (_policy == AtmFeePolicy.chargesFixed ||
                    _policy == AtmFeePolicy.chargesPercent) ...[
                  const SizedBox(height: AppSpacing.md),
                  _Field(
                    controller: _atmValue,
                    suffix: _policy == AtmFeePolicy.chargesFixed
                        ? widget.homeCurrency
                        : '%',
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _error!,
                    style: type.label.copyWith(color: AppColors.errorText),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Text(l10n.cardSheetPrivacy, style: type.footer),
                const SizedBox(height: AppSpacing.xl),
                AppButton(label: l10n.cardSheetSave, onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: HomeMetrics.grabberWidth,
      height: HomeMetrics.grabberHeight,
      decoration: const ShapeDecoration(
        shape: StadiumBorder(),
        color: AppColors.handle,
      ),
    ),
  );
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.suffix});

  final TextEditingController controller;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final type = AppTypography.of(context);
    return Surface(
      radius: AppRadius.md,
      color: AppColors.surfaceSunken,
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
              style: type.title.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              decoration: const InputDecoration(border: InputBorder.none),
            ),
          ),
          Text(suffix, style: type.bodyLg),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final type = AppTypography.of(context);
    return Pressable(
      onPressed: onPressed,
      semanticLabel: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: const StadiumBorder(),
            color: selected ? AppColors.surfaceDark : AppColors.surfaceSunken,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Text(
              label,
              style: type.label.copyWith(
                color: selected ? AppColors.onSurfaceDark : AppColors.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
