import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/colors.dart';
import '../../core/elevation.dart';
import '../../core/formatters.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../data/cash_wallet_store.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/cash_exchange.dart' show exchangeWalletCurrency;
import '../../rules/cash_wallet.dart';
import '../../shared/app_button.dart';
import '../../shared/pill.dart';
import '../../shared/pressable.dart';
import '../../shared/surface.dart';
import 'cash_exchange_screen.dart';
import 'home_metrics.dart';

/// "Cash on hand": the cash the traveler really holds, from the ledger of
/// recorded movements (an opening balance, ATM withdrawals, exchanges and
/// cash payments). The figure is always shown; before anything is recorded
/// it reads 0 while the ledger itself stays empty, so nothing is invented.
class CashBalanceCard extends StatelessWidget {
  const CashBalanceCard({
    super.key,
    required this.wallet,
    required this.currency,
    required this.foreignCurrency,
    required this.onFindNearby,
    this.demo = false,
    this.prominent = false,
  });

  final CashWalletStore wallet;
  final String currency;
  final String foreignCurrency;
  final VoidCallback onFindNearby;
  final bool demo;

  /// The screen's one big number (Assistant). On Home the trip total is
  /// that number, so the balance stays a step smaller there.
  final bool prominent;

  Future<void> _edit(BuildContext context, double? recorded) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _CashWalletSheet(
          wallet: wallet,
          currency: currency,
          balance: recorded,
          movements: wallet.movements
              .where((m) => m.currency == currency)
              .toList(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final recorded = wallet.balance(currency);
    final shown = displayedCashBalance(recorded);
    final last = wallet.movements
        .where((m) => m.currency == currency)
        .firstOrNull;
    final figure = prominent ? type.displayLg : type.headline;
    final String note;
    if (recorded == null) {
      note = l10n.cashWalletNotSet;
    } else if (recorded < 0) {
      note = l10n.cashWalletNegative;
    } else if (last != null) {
      note = l10n.cashWalletLastMove(
        last.description ?? _kindName(l10n, last.kind),
        '${last.signedAmount >= 0 ? '+' : '\u2212'}'
        '${AppFormat.roundedAmount(last.signedAmount.abs(), currency)}',
        DateFormat.MMMd(locale).add_Hm().format(last.at.toLocal()),
      );
    } else {
      note = l10n.cashWalletNotSet;
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.groupGap),
      child: Surface(
        radius: AppRadius.xl,
        color: AppColors.surface,
        shadows: AppElevation.e1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Pressable(
              onPressed: () => _edit(context, recorded),
              semanticLabel:
                  '${l10n.cashWalletTitle} '
                  '${AppFormat.roundedAmount(shown, currency)}. $note',
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.heroCardPadding,
                  AppSpacing.heroCardPadding,
                  AppSpacing.heroCardPadding,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.cashWalletTitle,
                            style: type.heroLabel,
                          ),
                        ),
                        if (demo) ...[
                          Pill(
                            label: l10n.tripMapSample,
                            fill: AppColors.surfaceDim,
                            textColor: AppColors.onSurfaceSecondary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Text(
                          l10n.cashWalletUpdate,
                          style: type.link.copyWith(
                            color: AppColors.primaryText,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: AppSizes.stepIcon,
                          color: AppColors.primaryText,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${shown < 0 ? '\u2212' : ''}'
                            '${AppFormat.roundedNumber(shown.abs())}',
                            style: figure.copyWith(
                              color: shown < 0
                                  ? AppColors.errorText
                                  : AppColors.onSurface,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          Text(
                            '\u00A0$currency',
                            style: type.title.copyWith(
                              color: AppColors.onSurfaceSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      note,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: type.rowSubtitle.copyWith(
                        color: recorded != null && recorded < 0
                            ? AppColors.errorText
                            : AppColors.onSurfaceTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              // Both tiles as tall as the taller label.
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _CardAction(
                        icon: Icons.atm_rounded,
                        label: l10n.atmMapTitle,
                        onPressed: onFindNearby,
                      ),
                    ),
                    // Live exchange counters are published for Thailand only.
                    if (currency == exchangeWalletCurrency) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _CardAction(
                          icon: Icons.currency_exchange_rounded,
                          label: l10n.exchangeFind,
                          onPressed: () => Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => CashExchangeScreen(
                                wallet: wallet,
                                walletCurrency: currency,
                                foreignCurrency: foreignCurrency,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _kindName(AppLocalizations l10n, CashMovementKind kind) =>
    switch (kind) {
      CashMovementKind.openingBalance ||
      CashMovementKind.adjustment => l10n.cashWalletSetBalance,
      CashMovementKind.withdrawal => l10n.cashWalletAtm,
      CashMovementKind.cashSpend => l10n.cashWalletSpent,
      CashMovementKind.exchange => l10n.cashWalletExchange,
    };

/// One of the card's two ways to get cash, on a sunken tile.
class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final type = AppTypography.of(context);
    return Pressable(
      onPressed: onPressed,
      semanticLabel: label,
      child: Surface(
        radius: AppRadius.md,
        color: AppColors.surfaceSunken,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
          child: Row(
            children: [
              Icon(icon, size: AppSizes.pillIcon, color: AppColors.primaryText),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: type.label.copyWith(color: AppColors.onSurface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _WalletMode { balance, add, spend }

class _CashWalletSheet extends StatefulWidget {
  const _CashWalletSheet({
    required this.wallet,
    required this.currency,
    required this.balance,
    required this.movements,
  });

  final CashWalletStore wallet;
  final String currency;
  final double? balance;
  final List<CashMovement> movements;

  @override
  State<_CashWalletSheet> createState() => _CashWalletSheetState();
}

class _CashWalletSheetState extends State<_CashWalletSheet> {
  late final _amount = TextEditingController(
    text: widget.balance == null
        ? ''
        : AppFormat.roundedNumber(widget.balance!),
  );
  late _WalletMode _mode = _WalletMode.balance;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  double? get _value =>
      double.tryParse(_amount.text.replaceAll(',', '').trim());

  Future<void> _save() async {
    final value = _value;
    if (value == null || !value.isFinite || value < 0) return;
    final l10n = AppLocalizations.of(context);
    switch (_mode) {
      case _WalletMode.balance:
        await widget.wallet.setBalance(
          amount: value,
          currency: widget.currency,
          description: l10n.cashWalletSetBalance,
        );
      case _WalletMode.add:
        await widget.wallet.recordManualMovement(
          amount: value,
          currency: widget.currency,
          spend: false,
          description: l10n.cashWalletAdded,
        );
      case _WalletMode.spend:
        await widget.wallet.recordManualMovement(
          amount: value,
          currency: widget.currency,
          spend: true,
          description: l10n.cashWalletSpent,
        );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final balance = widget.balance;
    final hasValue =
        _value != null &&
        (_mode == _WalletMode.balance ? _value! >= 0 : _value! > 0);
    final modes = [
      (mode: _WalletMode.balance, label: l10n.cashWalletSetBalance),
      (mode: _WalletMode.add, label: l10n.cashWalletAddCash),
      (mode: _WalletMode.spend, label: l10n.cashWalletSpendCash),
    ];
    final fieldLabel = switch (_mode) {
      _WalletMode.balance => l10n.cashWalletBalanceField,
      _WalletMode.add => l10n.cashWalletAddField,
      _WalletMode.spend => l10n.cashWalletSpendField,
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
                Center(
                  child: Container(
                    width: HomeMetrics.grabberWidth,
                    height: HomeMetrics.grabberHeight,
                    decoration: const ShapeDecoration(
                      shape: StadiumBorder(),
                      color: AppColors.handle,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.cashWalletTitle, style: type.title),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.cashWalletCurrent(
                    AppFormat.roundedAmount(balance ?? 0, widget.currency),
                  ),
                  style: type.rowSubtitle,
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final option in modes)
                      _ModeChoice(
                        label: option.label,
                        selected: _mode == option.mode,
                        onPressed: () => setState(() {
                          _mode = option.mode;
                          _amount.text = option.mode == _WalletMode.balance
                              ? (widget.balance == null
                                    ? ''
                                    : AppFormat.roundedNumber(widget.balance!))
                              : '';
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(fieldLabel, style: type.sectionHeader),
                const SizedBox(height: AppSpacing.sm),
                Surface(
                  radius: AppRadius.md,
                  color: AppColors.surfaceSunken,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _amount,
                          autofocus: true,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                          style: type.title.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) {
                            if (hasValue) _save();
                          },
                        ),
                      ),
                      Text(widget.currency, style: type.bodyLg),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: l10n.cashWalletSave,
                  onPressed: hasValue ? _save : null,
                ),
                // While the keyboard is up the field and Save stay in view;
                // the recent movements come back when it closes.
                if (widget.movements.isNotEmpty && inset == 0) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Surface(
                    radius: AppRadius.md,
                    color: AppColors.surfaceSunken,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    child: Column(
                      children: [
                        for (final m in widget.movements.take(4))
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xs,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    m.description ?? l10n.cashWalletTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: type.caption.copyWith(
                                      color: AppColors.onSurfaceSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  DateFormat.MMMd(locale)
                                      .add_Hm()
                                      .format(m.at.toLocal()),
                                  style: type.footer,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  '${m.signedAmount >= 0 ? '+' : '−'}${AppFormat.roundedAmount(m.signedAmount.abs(), m.currency)}',
                                  style: type.label.copyWith(
                                    color: m.signedAmount >= 0
                                        ? AppColors.primaryText
                                        : AppColors.onSurface,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeChoice extends StatelessWidget {
  const _ModeChoice({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onPressed,
      semanticLabel: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
        child: Center(
          widthFactor: 1,
          child: Pill(
            label: label,
            fill: selected ? AppColors.surfaceDark : AppColors.surfaceDim,
            textColor: selected ? AppColors.onSurfaceDark : AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}
