import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/colors.dart';
import '../../core/elevation.dart';
import '../../core/formatters.dart';
import '../../core/motion.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../data/market_price_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/haggle.dart';
import '../../shared/action_dock.dart';
import '../../shared/group.dart';
import '../../shared/pressable.dart';
import '../../shared/price_scale.dart';
import 'haggle_controller.dart';

/// Voice haggling: hear the seller, show what was said, judge it against the
/// sourced usual price, and say a counter-offer in Thai.
///
/// Zones: hero (live words while listening; the asked price and verdict
/// after), action (the dark counter-offer card), content (usual price with
/// its sources, then what was said), pinned dock.
class HaggleScreen extends StatefulWidget {
  const HaggleScreen({super.key});

  @override
  State<HaggleScreen> createState() => _HaggleScreenState();
}

class _HaggleScreenState extends State<HaggleScreen> {
  final _haggle = HaggleController();
  HaggleVerdict? _lastVerdict;

  @override
  void initState() {
    super.initState();
    _haggle.addListener(_onChanged);
    _haggle.start();
  }

  @override
  void dispose() {
    _haggle
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() {
    final verdict = _haggle.state.verdict;
    // One haggle feels like one event: tap when a verdict first appears.
    if (verdict != null && _lastVerdict?.verdict != verdict.verdict) {
      verdict.verdict == PriceVerdict.high
          ? HapticFeedback.mediumImpact()
          : HapticFeedback.lightImpact();
    }
    _lastVerdict = verdict;
    setState(() {});
  }

  /// For when the market is too loud: pick the item and key in the price.
  Future<void> _enterPrice() async {
    final entry = await showModalBottomSheet<(SourcedItem, double)>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PriceEntrySheet(items: _haggle.items),
    );
    if (entry != null) await _haggle.submitManual(entry.$1, entry.$2);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = _haggle.state;
    final listening = state.phase == HagglePhase.listening;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
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
                    sliver: SliverList.list(children: _content(l10n, state)),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ActionDock(
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _enterPrice,
                        child: Text(l10n.speakEnterPrice),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: switch (state.phase) {
                          HagglePhase.listening => _haggle.stopListening,
                          HagglePhase.done => () => _haggle.listen(),
                          _ => null,
                        },
                        icon: Icon(
                          listening ? Icons.stop_rounded : Icons.mic_rounded,
                        ),
                        label: Text(
                          listening ? l10n.speakStop : l10n.speakListenAgain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(AppLocalizations l10n, HaggleState state) {
    switch (state.phase) {
      case HagglePhase.preparing:
      case HagglePhase.listening:
        return [_ListeningHero(state: state)];
      case HagglePhase.unavailable:
      case HagglePhase.denied:
        return [
          _Message(
            title: state.phase == HagglePhase.denied
                ? l10n.speakDenied
                : l10n.speakUnavailable,
          ),
        ];
      case HagglePhase.done:
        return _doneContent(l10n, state);
    }
  }

  List<Widget> _doneContent(AppLocalizations l10n, HaggleState state) {
    final heard = state.heard;
    final match = state.match;
    final verdict = state.verdict;
    final saidSection = [
      const SizedBox(height: AppSpacing.zoneGap),
      SectionHeader(
        state.typed ? l10n.speakEntered : l10n.speakHeard,
        first: true,
      ),
      GroupCard(
        children: [
          if (state.typed)
            GroupRow(
              title: match?.item.nameEn ?? '',
              subtitle: heard == null ? null : _meaning(l10n, heard, match),
            )
          else
            GroupRow(
              title: state.words,
              titleStyle: AppTypography.thai.rowTitle,
              subtitle: heard == null ? null : _meaning(l10n, heard, match),
            ),
        ],
      ),
    ];

    if (heard != null && state.problem == HeardProblem.unknownItem) {
      // The price came through but not the item: offer the items sold in
      // the heard unit, so one tap finishes the check.
      final unit = heard.unit;
      final options = [
        for (final s in _haggle.items)
          if (unit == null || s.item.unit == unit) s,
      ];
      return [
        _Message(
          title: l10n.speakWhichItem,
          body: l10n.speakHeardPrice(_meaning(l10n, heard, null)),
        ),
        const SizedBox(height: AppSpacing.xl),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final s in options.isEmpty ? _haggle.items : options)
              _ItemChip(
                label: s.item.nameEn,
                selected: false,
                onPressed: () => _haggle.chooseItem(s),
              ),
          ],
        ),
        ...saidSection,
      ];
    }

    if (heard == null || match == null || verdict == null) {
      return [
        _Message(
          title: _problemTitle(l10n, state.problem),
          body: _problemTip(l10n, state.problem, heard, match),
        ),
        if (state.words.isNotEmpty) ...saidSection,
      ];
    }

    final item = match.item;
    final unit = _unitLabel(l10n, item.unit);
    final offer = verdict.counterOffer;
    return [
      _VerdictHero(
        amount: heard.amount,
        verdict: verdict,
        verdictLabel: _verdictLabel(l10n, verdict.verdict),
        meaning: item.nameEn,
        unit: unit,
        detail: switch (verdict.verdict) {
          PriceVerdict.high => l10n.speakOverBy(
            AppFormat.roundedAmount(verdict.overBy, marketCurrency),
          ),
          PriceVerdict.fair => l10n.speakFairBody,
          PriceVerdict.low => l10n.speakLowBody,
        },
      ),
      if (offer != null) ...[
        const SizedBox(height: AppSpacing.zoneGap),
        _CounterCard(
          label: l10n.speakCounterLabel,
          amount: l10n.speakCounterAmount(AppFormat.roundedNumber(offer)),
          sentence: l10n.counterOfferSentence(AppFormat.roundedNumber(offer)),
          sayIt: l10n.speakSayIt,
          speakingLabel: l10n.speakSpeaking,
          noVoice: l10n.speakNoVoice,
          canSpeak: state.canSpeak,
          speaking: state.speaking,
          onSpeak: () => _haggle.speakCounter(
            l10n.counterOfferSentence(AppFormat.roundedNumber(offer)),
          ),
        ),
      ],
      const SizedBox(height: AppSpacing.zoneGap),
      SectionHeader(l10n.speakUsualPrice, first: true),
      GroupCard(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.groupPaddingH,
              AppSpacing.xl,
              AppSpacing.groupPaddingH,
              AppSpacing.sm,
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: AppMotion.of(context, AppMotion.emphasized),
              curve: AppMotion.enter,
              builder: (_, t, _) => PriceScale(
                low: item.low,
                high: item.high,
                asked: heard.amount,
                progress: t,
              ),
            ),
          ),
          GroupRow(
            title: l10n.speakUsualRangeRow,
            value: l10n.speakUsualRange(
              AppFormat.roundedNumber(item.low),
              AppFormat.roundedNumber(item.high),
              unit,
            ),
            valueStyle: AppTypography.of(context).rowTitle
                .copyWith(color: AppColors.primaryText),
          ),
          GroupRow(
            title: l10n.speakAsked,
            value: AppFormat.roundedAmount(heard.amount, marketCurrency),
            valueStyle: verdict.verdict == PriceVerdict.high
                ? AppTypography.of(context).rowTitle
                      .copyWith(color: AppColors.errorText)
                : null,
          ),
        ],
      ),
      GroupFooter(_sourcesLine(l10n, match)),
      ...saidSection,
    ];
  }

  String _sourcesLine(AppLocalizations l10n, SourcedItem match) {
    final hosts = {
      for (final s in match.sources)
        Uri.parse(s.url).host.replaceFirst('www.', ''),
    };
    final dates = match.sources.map((s) => DateTime.parse(s.date)).toList()
      ..sort();
    final locale = Localizations.localeOf(context).toLanguageTag();
    final first = dates.first;
    final last = dates.last;
    final sameMonth = first.year == last.year && first.month == last.month;
    final months = sameMonth
        ? DateFormat.yMMM(locale).format(last)
        : l10n.speakMonthRange(
            DateFormat.MMM(locale).format(first),
            DateFormat.yMMM(locale).format(last),
          );
    return l10n.speakSourcesLine(
      hosts.join(l10n.listSeparator),
      l10n.speakSources(match.sources.length, months),
    );
  }

  String _meaning(AppLocalizations l10n, HeardPrice heard, SourcedItem? match) {
    final amount = AppFormat.roundedAmount(heard.amount, marketCurrency);
    final unit = heard.unit ?? match?.item.unit;
    final item = match?.item.nameEn;
    if (item == null) {
      return unit == null ? amount : '$amount ${_unitLabel(l10n, unit)}';
    }
    return l10n
        .speakMeaning(item, amount, unit == null ? '' : _unitLabel(l10n, unit))
        .trim();
  }

  static String _unitLabel(AppLocalizations l10n, PriceUnit unit) =>
      switch (unit) {
        PriceUnit.perKg => l10n.unitPerKg,
        PriceUnit.each => l10n.unitEach,
        PriceUnit.perPlate => l10n.unitPerPlate,
        PriceUnit.perHour => l10n.unitPerHour,
        PriceUnit.perRide => l10n.unitPerRide,
      };

  static String _verdictLabel(AppLocalizations l10n, PriceVerdict v) =>
      switch (v) {
        PriceVerdict.high => l10n.verdictHigh,
        PriceVerdict.fair => l10n.verdictFair,
        PriceVerdict.low => l10n.verdictLow,
      };

  static String _problemTitle(AppLocalizations l10n, HeardProblem? p) =>
      switch (p) {
        HeardProblem.noPrice => l10n.speakNoPrice,
        HeardProblem.unknownItem => l10n.speakUnknownItem,
        HeardProblem.unitMismatch => l10n.speakUnitMismatch,
        HeardProblem.nothingHeard || null => l10n.speakNothingHeard,
      };

  String _problemTip(
    AppLocalizations l10n,
    HeardProblem? p,
    HeardPrice? heard,
    SourcedItem? match,
  ) => switch (p) {
    HeardProblem.noPrice => l10n.speakNoPriceTip,
    HeardProblem.unknownItem => l10n.speakUnknownItemTip(
      AppFormat.roundedAmount(heard!.amount, marketCurrency),
    ),
    HeardProblem.unitMismatch => l10n.speakUnitMismatchTip(
      _unitLabel(l10n, match!.item.unit),
    ),
    HeardProblem.nothingHeard || null => l10n.speakNothingHeardTip,
  };
}

/// Hero while listening: a waveform driven by the real microphone level and
/// the Thai words as they are recognized.
class _ListeningHero extends StatefulWidget {
  const _ListeningHero({required this.state});

  final HaggleState state;

  @override
  State<_ListeningHero> createState() => _ListeningHeroState();
}

class _ListeningHeroState extends State<_ListeningHero> {
  final _levels = List<double>.filled(
    AppSizes.waveformSamples,
    0,
    growable: true,
  );

  @override
  void didUpdateWidget(_ListeningHero old) {
    super.didUpdateWidget(old);
    if (widget.state.phase == HagglePhase.listening) {
      _levels
        ..removeAt(0)
        ..add(widget.state.level);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final words = widget.state.words;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.state.phase == HagglePhase.preparing
              ? l10n.speakPreparing
              : l10n.speakListening,
          style: type.heroLabel,
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: AppSizes.waveformHeight,
          child: CustomPaint(
            size: Size.infinite,
            painter: _WaveformPainter(List.of(_levels)),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AnimatedSwitcher(
          duration: AppMotion.of(context, AppMotion.quick),
          child: words.isEmpty
              ? Text(
                  l10n.speakListenHint,
                  key: const ValueKey('hint'),
                  style: type.title.copyWith(
                    color: AppColors.onSurfaceTertiary,
                  ),
                )
              : Text(
                  words,
                  key: const ValueKey('words'),
                  style: AppTypography.thai.headline,
                ),
        ),
      ],
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter(this.levels);

  final List<double> levels;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.onSurface
      ..strokeCap = StrokeCap.round
      ..strokeWidth = AppSizes.waveformBar;
    const step = AppSizes.waveformBar + AppSizes.waveformGap;
    final count = (size.width / step).floor().clamp(1, levels.length);
    final recent = levels.sublist(levels.length - count);
    final cy = size.height / 2;
    for (var i = 0; i < recent.length; i++) {
      final h =
          size.height *
          (AppSizes.waveformMinBar + (1 - AppSizes.waveformMinBar) * recent[i]);
      final x = i * step + AppSizes.waveformBar / 2;
      canvas.drawLine(Offset(x, cy - h / 2), Offset(x, cy + h / 2), paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) => true;
}

/// Hero after listening: the asked price is the largest thing on screen,
/// with the verdict chip and the meaning in English.
class _VerdictHero extends StatelessWidget {
  const _VerdictHero({
    required this.amount,
    required this.verdict,
    required this.verdictLabel,
    required this.meaning,
    required this.unit,
    required this.detail,
  });

  final double amount;
  final HaggleVerdict verdict;
  final String verdictLabel;
  final String meaning;
  final String unit;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final type = AppTypography.of(context);
    final high = verdict.verdict == PriceVerdict.high;
    final (chipFill, chipText) = switch (verdict.verdict) {
      PriceVerdict.high => (AppColors.errorContainer, AppColors.errorText),
      PriceVerdict.fair => (
        AppColors.primaryContainer,
        AppColors.onPrimaryContainer,
      ),
      PriceVerdict.low => (AppColors.surfaceDim, AppColors.onSurface),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).speakHeroLabel(meaning, unit),
          style: type.heroLabel,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            // Long prices shrink to fit instead of pushing the chip off.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      AppFormat.roundedNumber(amount),
                      style: type.displayXl.copyWith(
                        color: high ? AppColors.errorText : AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(marketCurrency, style: type.title),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            DecoratedBox(
              decoration: BoxDecoration(
                color: chipFill,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.chipPadding,
                ),
                child: Text(
                  verdictLabel,
                  style: type.label.copyWith(color: chipText),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          detail,
          style: type.bodyMd.copyWith(color: AppColors.onSurfaceSecondary),
        ),
      ],
    );
  }
}

/// The one dark card: the price to ask for, the Thai sentence, and a button
/// that says it aloud.
class _CounterCard extends StatelessWidget {
  const _CounterCard({
    required this.label,
    required this.amount,
    required this.sentence,
    required this.sayIt,
    required this.speakingLabel,
    required this.noVoice,
    required this.canSpeak,
    required this.speaking,
    required this.onSpeak,
  });

  final String label;
  final String amount;
  final String sentence;
  final String sayIt;
  final String speakingLabel;
  final String noVoice;
  final bool canSpeak;
  final bool speaking;
  final VoidCallback onSpeak;

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
            amount,
            style: type.headline.copyWith(color: AppColors.onSurfaceDark),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            sentence,
            style: AppTypography.thai.title.copyWith(
              color: AppColors.onSurfaceDark,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (canSpeak)
            Pressable(
              semanticLabel: sayIt,
              onPressed: speaking ? null : onSpeak,
              child: Container(
                height: AppSizes.buttonHeight,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      speaking
                          ? Icons.graphic_eq_rounded
                          : Icons.volume_up_rounded,
                      color: AppColors.onPrimary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      speaking ? speakingLabel : sayIt,
                      style: type.bodyLg.copyWith(color: AppColors.onPrimary),
                    ),
                  ],
                ),
              ),
            )
          else
            Text(
              noVoice,
              style: type.bodyMd.copyWith(
                color: AppColors.onSurfaceDarkSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

/// A problem or unavailable state, written as the hero.
class _Message extends StatelessWidget {
  const _Message({required this.title, this.body});

  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final type = AppTypography.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: type.headline),
        if (body != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            body!,
            style: type.bodyMd.copyWith(color: AppColors.onSurfaceSecondary),
          ),
        ],
      ],
    );
  }
}

/// Sheet for entering the price by hand when the market is too loud: pick
/// the item, key in the number. No Thai typing needed.
class _PriceEntrySheet extends StatefulWidget {
  const _PriceEntrySheet({required this.items});

  final List<SourcedItem> items;

  @override
  State<_PriceEntrySheet> createState() => _PriceEntrySheetState();
}

class _PriceEntrySheetState extends State<_PriceEntrySheet> {
  final _price = TextEditingController();
  SourcedItem? _item;

  @override
  void initState() {
    super.initState();
    _price.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  double? get _amount => double.tryParse(_price.text.replaceAll(',', ''));

  void _submit() {
    final item = _item;
    final amount = _amount;
    if (item == null || amount == null || amount <= 0) return;
    Navigator.of(context).pop((item, amount));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    final ready = _item != null && (_amount ?? 0) > 0;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sheetPadding,
        AppSpacing.sheetPadding,
        AppSpacing.sheetPadding,
        AppSpacing.sheetPadding + insets,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.speakEnterTitle, style: type.title),
          const SizedBox(height: AppSpacing.xl),
          Text(l10n.speakPickItem, style: type.sectionHeader),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final s in widget.items)
                _ItemChip(
                  label: s.item.nameEn,
                  selected: _item == s,
                  onPressed: () => setState(() => _item = s),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(l10n.speakPriceLabel, style: type.sectionHeader),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            style: type.title,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              suffixText: marketCurrency,
              filled: true,
              fillColor: AppColors.surfaceSunken,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: ready ? _submit : null,
              child: Text(l10n.speakTypeSubmit),
            ),
          ),
        ],
      ),
    );
  }
}

/// A pill for choosing an item; dark when selected.
class _ItemChip extends StatelessWidget {
  const _ItemChip({
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
      semanticLabel: label,
      onPressed: onPressed,
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.quick),
        constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceDark : AppColors.surfaceDim,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(
          label,
          style: type.label.copyWith(
            color: selected ? AppColors.onSurfaceDark : AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}
