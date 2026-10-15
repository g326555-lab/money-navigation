import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../app/app_scope.dart';
import '../../core/colors.dart';
import '../../core/elevation.dart';
import '../../core/formatters.dart';
import '../../core/motion.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/atm_conversion.dart';
import '../../rules/trip_ledger.dart';
import '../../shared/action_dock.dart';
import '../../shared/app_button.dart';
import '../../shared/aura_field.dart';
import '../../shared/coin.dart';
import '../../shared/group.dart';
import '../../shared/land_in.dart';
import '../../shared/pill.dart';
import 'scan_controller.dart';
import '../../shared/surface.dart';
import '../../shared/content_width.dart';
import '../../services/ai/ai_trace.dart';

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
    final checkedAt =
        (MediaQuery.alwaysUse24HourFormatOf(context)
                ? DateFormat.Hm()
                : DateFormat.jm())
            .format(state.scannedAt!);
    final details = _details(l10n, type, keeps, checkedAt);
    if (keeps) {
      return SuccessView(
        hero: SuccessHero(
          label: l10n.atmKeepLabel,
          amount: verdict.extraCostThb,
          unit: atmLocalCurrency,
          chip: AppFormat.cents(verdict.extraCostUsd, atmCardCurrency),
        ),
        press: PressCard(
          label: l10n.atmPress,
          action: state.declineLabel ?? l10n.atmDeclineButton,
          reason: reading.markupPercent == null
              ? l10n.atmReasonNoMarkup
              : l10n.atmReasonMarkup(AppFormat.percent(reading.markupPercent!)),
        ),
        details: details,
        closeLabel: l10n.scanClose,
        actionLabel: l10n.atmScanAnother,
        saveLabel: l10n.saveToTrip,
        onSave: () => _save(context),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        // The dock floats over the content, so its blur has something to
        // blur; the scroll view stays below the status bar.
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: ContentWidth(
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
                          Text(l10n.atmEvenTitle, style: type.headline),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            l10n.atmEvenBody,
                            style: type.bodyMd.copyWith(
                              color: AppColors.onSurfaceSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.zoneGap),
                          ...details,
                        ],
                      ),
                    ),
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

  /// Adds what this verdict kept to the trip, then goes Home, where the
  /// total counts up to include it. One scan saves once.
  Future<void> _save(BuildContext context) async {
    final scope = AppScope.of(context);
    final trip = scope.trip;
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final save = saveFromAtm(
      state.verdict!,
      id: 'atm-${state.scannedAt!.microsecondsSinceEpoch}',
      savedAt: DateTime.now(),
      reading: state.reading,
    );
    if (save == null) return;
    if (!trip.contains(save.id)) await trip.add(save);
    final withdrawal = state.reading?.withdrawalThb;
    if (withdrawal != null) {
      await scope.cashWallet.addCash(
        amount: withdrawal,
        currency: atmLocalCurrency,
        sourceId: save.id,
        description: l10n.cashWalletAtm,
        at: state.scannedAt,
      );
    }
    HapticFeedback.mediumImpact();
    navigator.popUntil((route) => route.isFirst);
  }

  List<Widget> _details(
    AppLocalizations l10n,
    AppTypography type,
    bool keeps,
    String checkedAt,
  ) {
    final reading = state.reading!;
    return [
      SectionHeader(l10n.atmBothTotals, first: true),
      GroupCard(
        children: [
          GroupRow(
            title: l10n.atmIfConvert,
            subtitle: l10n.atmIfConvertDetail,
            value: AppFormat.cents(reading.chargedUsd, atmCardCurrency),
          ),
          GroupRow(
            title: l10n.atmIfNotConvert,
            subtitle: l10n.atmIfNotConvertDetail,
            value: AppFormat.amount(reading.chargedThb, atmLocalCurrency),
            valueStyle: keeps
                ? type.rowTitle.copyWith(color: AppColors.primaryText)
                : null,
          ),
        ],
      ),
      SectionHeader(l10n.atmOnScreen),
      GroupCard(
        children: [
          GroupRow(
            title: l10n.atmRowWithdrawal,
            value: AppFormat.amount(reading.withdrawalThb, atmLocalCurrency),
          ),
          GroupRow(
            title: l10n.atmRowFee,
            value: AppFormat.amount(reading.accessFeeThb, atmLocalCurrency),
          ),
          GroupRow(
            title: l10n.atmRowRate,
            value: l10n.atmRateValue(AppFormat.rate(reading.thbPerUsd)),
          ),
          if (reading.markupPercent != null)
            GroupRow(
              title: l10n.atmRowMarkup,
              value: AppFormat.percent(reading.markupPercent!),
            ),
        ],
      ),
      GroupFooter(l10n.atmSource(checkedAt)),
      if (state.readElapsed case final read?)
        GroupFooter(
          l10n.aiTrace(
            AiEngine.onDevice.displayName,
            AiTrace(AiEngine.onDevice, read).elapsedLabel,
          ),
        ),
    ];
  }
}

/// DESIGN.md success template: a full green field with the coin, one very
/// large number and one white card. The details live on a page-colored
/// sheet that scrolls up over the field.
class SuccessView extends StatelessWidget {
  const SuccessView({
    super.key,
    required this.hero,
    required this.press,
    required this.details,
    required this.closeLabel,
    required this.actionLabel,
    required this.saveLabel,
    required this.onSave,
  });

  final Widget hero;
  final Widget press;
  final List<Widget> details;
  final String closeLabel;
  final String actionLabel;
  final String saveLabel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    // Short screens (the Fold cover) tighten the field so the details
    // sheet's handle shows above the dock and invites a scroll.
    final compact = MediaQuery.sizeOf(context).height <= AppSizes.compactHeight;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Stack(
          children: [
            const Positioned.fill(child: AuraField()),
            SafeArea(
              bottom: false,
              child: ContentWidth(
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
                            tooltip: closeLabel,
                            icon: const Icon(Icons.close_rounded),
                            color: AppColors.onSuccess,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenMargin,
                        0,
                        AppSpacing.screenMargin,
                        AppSpacing.zoneGap,
                      ),
                      sliver: SliverList.list(
                        children: [
                          hero,
                          SizedBox(
                            height: compact
                                ? AppSpacing.xxl
                                : AppSpacing.zoneGap,
                          ),
                          LandIn(delay: AppMotion.pressCardDelay, child: press),
                        ],
                      ),
                    ),
                    // The sheet sizes to its own content. Rows lay out with
                    // a LayoutBuilder, which cannot report an intrinsic
                    // height, so the sheet must not sit in a
                    // SliverFillRemaining itself; an empty filler below it
                    // carries the page color to the bottom instead.
                    SliverToBoxAdapter(
                      child: DecoratedBox(
                        decoration: ShapeDecoration(
                          color: AppColors.background,
                          shape: const RoundedSuperellipseBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(AppRadius.sheet),
                            ),
                          ),
                          shadows: AppElevation.e2Sheet,
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.screenMargin,
                            AppSpacing.md,
                            AppSpacing.screenMargin,
                            AppSpacing.zoneGap + ActionDock.heightOf(context),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Container(
                                  width: AppSizes.sheetHandleWidth,
                                  height: AppSizes.sheetHandleHeight,
                                  decoration: BoxDecoration(
                                    color: AppColors.handle,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.full,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              ...details,
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: ColoredBox(color: AppColors.background),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ActionDock(
                child: DockPair(
                  secondaryLabel: actionLabel,
                  onSecondary: () => Navigator.of(context).pop(),
                  primaryLabel: saveLabel,
                  onPrimary: onSave,
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
class SuccessHero extends StatefulWidget {
  const SuccessHero({
    super.key,
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
  State<SuccessHero> createState() => _SuccessHeroState();
}

class _SuccessHeroState extends State<SuccessHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _count = AnimationController(
    vsync: this,
    duration: AppMotion.emphasized,
  )..addStatusListener(_onStatus);

  /// True once the amount has landed; starts the coin burst.
  bool _landed = false;

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
    if (status == AnimationStatus.completed) {
      HapticFeedback.successNotification();
      setState(() => _landed = true);
    }
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
    final pop = CurvedAnimation(parent: _count, curve: AppMotion.heroPop);
    final coin = CurvedAnimation(parent: _count, curve: AppMotion.settle);
    final coinFade = CurvedAnimation(
      parent: _count,
      curve: AppMotion.heroCoinFade,
    );
    final number = type.displayXl.copyWith(color: AppColors.onSuccess);
    return Column(
      children: [
        // The coin lands with the number: it grows in on the same settle
        // curve, so both arrive as one moment.
        AnimatedBuilder(
          animation: _count,
          builder: (_, child) => Transform.scale(
            scale:
                AppMotion.coinStartScale +
                (1 - AppMotion.coinStartScale) * coin.value,
            child: Opacity(opacity: coinFade.value, child: child),
          ),
          // Once the amount lands, a few coins pop from behind it.
          child: CoinBurst(
            play: _landed,
            child: LivingCoin(
              size: MediaQuery.sizeOf(context).height <= AppSizes.compactHeight
                  ? AppSizes.heroCoinCompact
                  : AppSizes.heroCoin,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          widget.label,
          style: type.heroLabel.copyWith(color: AppColors.onSuccess),
        ),
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
                      alignment: Alignment.bottomCenter,
                      child: Stack(
                        // Counting digits sit against the unit, so no gap
                        // opens before "THB" while the width is reserved.
                        alignment: Alignment.bottomRight,
                        children: [
                          // Reserves the final width.
                          Opacity(
                            opacity: 0,
                            child: Text(finalText, style: number),
                          ),
                          Text(
                            AppFormat.roundedNumber(
                              widget.amount * count.value,
                            ),
                            style: number,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const TextSpan(text: ' '),
                TextSpan(
                  text: widget.unit,
                  style: type.title.copyWith(color: AppColors.onSuccess),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Pill.onGreen(label: widget.chip, shadows: AppElevation.pillOnGreen),
      ],
    );
  }
}

/// The one white card on the success field: the button to press and why.
class PressCard extends StatelessWidget {
  const PressCard({
    super.key,
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
    return Surface(
      radius: AppRadius.xl,
      color: AppColors.surface,
      shadows: AppElevation.e1Green,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: type.label.copyWith(color: AppColors.onPrimaryContainer),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(action, style: type.title),
          const SizedBox(height: AppSpacing.lg),
          const Divider(
            height: AppSizes.hairline,
            thickness: AppSizes.hairline,
            color: AppColors.divider,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            reason,
            style: type.bodyMd.copyWith(color: AppColors.onSurfaceSecondary),
          ),
        ],
      ),
    );
  }
}
