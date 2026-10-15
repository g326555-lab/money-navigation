import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/colors.dart';
import '../../core/elevation.dart';
import '../../core/formatters.dart';
import '../../core/motion.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/atm_conversion.dart';
import '../../shared/action_dock.dart';
import '../../shared/group.dart';
import 'scan_controller.dart';

/// Verdict for an ATM conversion offer: what to press and how much it keeps.
///
/// Zones: hero (amount kept), action (the dark "Press" card), content
/// (both totals, then the numbers read from the screen), pinned action dock.
class AtmResultScreen extends StatelessWidget {
  const AtmResultScreen({super.key, required this.state});

  final ScanState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final reading = state.reading!;
    final verdict = state.verdict!;
    final keeps =
        verdict.recommended == AtmChoice.declineConversion &&
        verdict.extraCostThb.round() > 0;
    final checkedAt = DateFormat.Hm().format(state.scannedAt!);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        // The dock floats over the content, so its blur has something to
        // blur; the scroll view stays below the status bar.
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          tooltip: l10n.scanClose,
                          icon: const Icon(Icons.close_rounded),
                          color: AppColors.onSurface,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.screenMargin,
                      AppSpacing.sm,
                      AppSpacing.screenMargin,
                      AppSpacing.zoneGap + ActionDock.heightOf(context),
                    ),
                    sliver: SliverList.list(
                      children: [
                        if (keeps) ...[
                          _Hero(
                            label: l10n.atmKeepLabel,
                            amount: verdict.extraCostThb,
                            unit: atmLocalCurrency,
                            chip: AppFormat.cents(
                              verdict.extraCostUsd,
                              atmCardCurrency,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.zoneGap),
                          _PressCard(
                            label: l10n.atmPress,
                            action: state.declineLabel ?? l10n.atmDeclineButton,
                            reason: reading.markupPercent == null
                                ? l10n.atmReasonNoMarkup
                                : l10n.atmReasonMarkup(
                                    AppFormat.percent(reading.markupPercent!),
                                  ),
                          ),
                        ] else ...[
                          Text(l10n.atmEvenTitle, style: type.headline),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            l10n.atmEvenBody,
                            style: type.bodyMd.copyWith(
                              color: AppColors.onSurfaceSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.zoneGap),
                        SectionHeader(l10n.atmBothTotals, first: true),
                        GroupCard(
                          children: [
                            GroupRow(
                              title: l10n.atmIfConvert,
                              subtitle: l10n.atmIfConvertDetail,
                              value: AppFormat.cents(
                                reading.chargedUsd,
                                atmCardCurrency,
                              ),
                            ),
                            GroupRow(
                              title: l10n.atmIfNotConvert,
                              subtitle: l10n.atmIfNotConvertDetail,
                              value: AppFormat.amount(
                                reading.chargedThb,
                                atmLocalCurrency,
                              ),
                              valueStyle: keeps
                                  ? type.rowTitle.copyWith(
                                      color: AppColors.primaryText,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                        SectionHeader(l10n.atmOnScreen),
                        GroupCard(
                          children: [
                            GroupRow(
                              title: l10n.atmRowWithdrawal,
                              value: AppFormat.amount(
                                reading.withdrawalThb,
                                atmLocalCurrency,
                              ),
                            ),
                            GroupRow(
                              title: l10n.atmRowFee,
                              value: AppFormat.amount(
                                reading.accessFeeThb,
                                atmLocalCurrency,
                              ),
                            ),
                            GroupRow(
                              title: l10n.atmRowRate,
                              value: l10n.atmRateValue(
                                AppFormat.rate(reading.thbPerUsd),
                              ),
                            ),
                            if (reading.markupPercent != null)
                              GroupRow(
                                title: l10n.atmRowMarkup,
                                value: AppFormat.percent(
                                  reading.markupPercent!,
                                ),
                              ),
                          ],
                        ),
                        GroupFooter(l10n.atmSource(checkedAt)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ActionDock(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.atmScanAnother),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hero zone: sits on the page, no card. One label, the largest number on
/// the screen, one chip.
///
/// The amount counts up from zero to the real verdict value while the page
/// rises and settles with a slight overshoot in scale, then a haptic
/// confirms it. The final
/// figure reserves its width from the start, so the unit never shifts.
class _Hero extends StatefulWidget {
  const _Hero({
    required this.label,
    required this.amount,
    required this.unit,
    required this.chip,
  });

  final String label;
  final double amount;
  final String unit;
  final String chip;

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> with SingleTickerProviderStateMixin {
  late final AnimationController _count = AnimationController(
    vsync: this,
    duration: AppMotion.emphasized,
  )..addStatusListener(_onStatus);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_count.value > 0 || _count.isAnimating) return;
    final duration = AppMotion.of(context, AppMotion.emphasized);
    if (duration == Duration.zero) {
      _count.value = 1;
      HapticFeedback.mediumImpact();
      return;
    }
    _count.duration = duration;
    // Counts while the screen rises, so the amount is already climbing when
    // the page lands and never sits at zero; it settles as the page does.
    // The first frame is skipped so the count's first step is not lost to
    // route setup.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _count.forward();
    });
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _count.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = AppTypography.of(context);
    final finalText = AppFormat.roundedNumber(widget.amount);
    final count = CurvedAnimation(parent: _count, curve: AppMotion.enter);
    final pop = CurvedAnimation(
      parent: _count,
      curve: const Interval(0.6, 1, curve: AppMotion.settle),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: type.heroLabel),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          label: '$finalText ${widget.unit}',
          excludeSemantics: true,
          child: Text.rich(
            TextSpan(
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: AnimatedBuilder(
                    animation: _count,
                    builder: (_, _) => Transform.scale(
                      // Grows a little past full size and settles back.
                      scale:
                          AppMotion.heroSettleFrom +
                          (1 - AppMotion.heroSettleFrom) * pop.value,
                      alignment: Alignment.bottomLeft,
                      child: Stack(
                        // Counting digits sit against the unit, so no gap
                        // opens before "THB" while the width is reserved.
                        alignment: Alignment.bottomRight,
                        children: [
                          // Reserves the final width.
                          Opacity(
                            opacity: 0,
                            child: Text(finalText, style: type.displayXl),
                          ),
                          Text(
                            AppFormat.roundedNumber(
                              widget.amount * count.value,
                            ),
                            style: type.displayXl,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const TextSpan(text: ' '),
                TextSpan(text: widget.unit, style: type.title),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.chipPadding,
            ),
            child: Text(
              widget.chip,
              style: type.label.copyWith(color: AppColors.onPrimaryContainer),
            ),
          ),
        ),
      ],
    );
  }
}

/// The one dark card on the screen: the button to press and why.
class _PressCard extends StatelessWidget {
  const _PressCard({
    required this.label,
    required this.action,
    required this.reason,
  });

  final String label;
  final String action;
  final String reason;

  @override
  Widget build(BuildContext context) {
    final type = AppTypography.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppElevation.e1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: type.label.copyWith(color: AppColors.primaryOnDark),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            action,
            style: type.title.copyWith(color: AppColors.onSurfaceDark),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(
            height: AppSizes.hairline,
            thickness: AppSizes.hairline,
            color: AppColors.dividerOnDark,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            reason,
            style: type.bodyMd.copyWith(
              color: AppColors.onSurfaceDarkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
