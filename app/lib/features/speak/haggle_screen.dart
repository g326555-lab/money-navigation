import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../app/app_scope.dart';
import '../../core/colors.dart';
import '../../core/elevation.dart';
import '../../core/formatters.dart';
import '../../core/motion.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../data/market_price_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/haggle.dart';
import '../../rules/haggle_rounds.dart';
import '../../rules/new_item.dart';
import '../../rules/new_item_counter.dart';
import '../../rules/personal_context.dart';
import '../../rules/trip_ledger.dart';
import '../../services/ai/ai_trace.dart';
import '../../services/ai/gemini_explainer.dart';
import '../../services/ai/price_reference.dart';
import '../../shared/action_dock.dart';
import '../../shared/app_button.dart';
import '../../shared/group.dart';
import '../../shared/pill.dart';
import '../../shared/pressable.dart';
import '../../shared/price_scale.dart';
import '../settings/settings_screen.dart' show endingText, statementEndingText;
import 'haggle_controller.dart';
import 'show_seller_screen.dart';
import '../../shared/surface.dart';
import '../../shared/content_width.dart';

/// Voice haggling: hear the seller, show what was said, judge it against the
/// sourced usual price, and say a counter-offer in Thai.
///
/// Zones: hero (live words while listening; the asked price and verdict
/// after), action (the dark counter-offer card), content (usual price with
/// its sources, then what was said), pinned dock.
class HaggleScreen extends StatefulWidget {
  const HaggleScreen({super.key, this.controller});

  /// Supplied by tests and screen captures; the screen makes its own
  /// otherwise.
  final HaggleController? controller;

  @override
  State<HaggleScreen> createState() => _HaggleScreenState();
}

class _HaggleScreenState extends State<HaggleScreen>
    with WidgetsBindingObserver {
  late final _haggle = widget.controller ?? HaggleController();
  HaggleVerdict? _lastVerdict;

  /// Gemini's plain-English wording of the verdict, when it answers in
  /// time. Optional: the verified figures never wait for it.
  final _explainer = GeminiExplainer();
  String? _explainedFor;
  (String, AiTrace)? _explained;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _haggle.addListener(_onChanged);
    _haggle.start();
  }

  /// Coming back from Settings: if the microphone was off, check again.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _haggle.state.phase == HagglePhase.denied) {
      _haggle.start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
          ? HapticFeedback.warningNotification()
          : HapticFeedback.lightImpact();
    }
    _lastVerdict = verdict;
    _explain();
    setState(() {});
  }

  /// Asks Gemini once per heard price to reword the verified facts.
  /// English only: the sentence comes back in English.
  void _explain() {
    final state = _haggle.state;
    final verdict = state.verdict;
    final match = state.match;
    final heard = state.heard;
    if (verdict == null || match == null || heard == null) return;
    if (Localizations.localeOf(context).languageCode != 'en') return;
    final key = '${match.item.key}:${heard.amount}';
    if (key == _explainedFor) return;
    _explainedFor = key;
    _explained = null;
    final item = match.item;
    _explainer
        .explain({
          'item': item.nameEn,
          'askedThb': heard.amount,
          'usualLowThb': item.low,
          'usualHighThb': item.high,
          'verdict': verdict.verdict.name,
          if (verdict.overBy > 0) 'overByThb': verdict.overBy,
          'counterOfferThb': ?verdict.counterOffer,
        })
        .then((answer) {
          if (!mounted || _explainedFor != key) return;
          setState(() => _explained = answer);
        });
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

  /// True while an offer is on the table and the seller has not settled it.
  bool get _stillHaggling {
    if (_haggle.state.verdict?.counterOffer == null) return false;
    final exchanges = _haggle.exchanges;
    return exchanges.isEmpty || exchanges.last.move.kind == MoveKind.offer;
  }

  /// Asks what was really paid, saves what that kept, then goes Home.
  Future<void> _saveToTrip() async {
    final state = _haggle.state;
    final heard = state.heard;
    final itemKey = state.match?.item.key ?? _haggle.newItem?.key;
    if (heard == null || itemKey == null) return;
    final trip = AppScope.of(context).trip;
    final navigator = Navigator.of(context);
    final paid = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PaidSheet(
        asked: heard.amount,
        // The agreed price, or the seller's last one, once they answered.
        offer: _haggle.exchanges.isEmpty
            ? (state.verdict?.counterOffer ?? _newItemCounter(state)?.offerThb)
            : _haggle.exchanges.last.move.price,
      ),
    );
    if (paid == null) return;
    final save = saveFromHaggle(
      id: 'haggle-${DateTime.now().microsecondsSinceEpoch}',
      savedAt: DateTime.now(),
      itemKey: itemKey,
      askedThb: heard.amount,
      paidThb: paid,
      placeName: _haggle.places?.place.name,
      placeLat: _haggle.places?.lat,
      placeLng: _haggle.places?.lng,
      sellerPrices: _haggle.history?.sellerPrices,
      ourOffers: _haggle.history?.ourOffers,
    );
    if (save == null) return;
    await trip.add(save);
    HapticFeedback.mediumImpact();
    navigator.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = _haggle.state;
    final listening = state.phase == HagglePhase.listening;
    final newItem = _haggle.newItem;
    final canSave =
        state.phase == HagglePhase.done &&
        state.heard != null &&
        ((state.verdict != null && state.match != null) || newItem != null);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              tooltip: l10n.scanClose,
                              icon: const Icon(Icons.close_rounded),
                              color: AppColors.onSurface,
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            if (canSave)
                              TextButton(
                                onPressed: _enterPrice,
                                child: Text(l10n.speakEnterPrice),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.screenMargin,
                        AppSpacing.sm,
                        AppSpacing.screenMargin,
                        AppSpacing.zoneGap +
                            ActionDock.heightOf(context) +
                            // The reply chips sit in the dock while haggling.
                            (_stillHaggling
                                ? AppSizes.minTouchTarget + AppSpacing.md
                                : 0),
                      ),
                      sliver: SliverList.list(children: _content(l10n, state)),
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
                child: switch (state.phase) {
                  HagglePhase.denied => DockPair(
                    secondaryLabel: l10n.speakEnterPrice,
                    onSecondary: _enterPrice,
                    primaryLabel: l10n.speakOpenSettings,
                    onPrimary: () => AppSettings.openAppSettings(),
                  ),
                  HagglePhase.unavailable => AppButton(
                    label: l10n.speakEnterPrice,
                    onPressed: _enterPrice,
                  ),
                  _ =>
                    canSave
                        ? (_stillHaggling
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _replyChips(l10n),
                                    const SizedBox(height: AppSpacing.md),
                                    DockPair(
                                      secondaryLabel: l10n.haggleNewPrice,
                                      onSecondary: () => _haggle.listen(),
                                      primaryIcon: Icons.mic_rounded,
                                      primaryLabel: l10n.haggleHearAnswer,
                                      onPrimary: _haggle.listenForReply,
                                    ),
                                  ],
                                )
                              : DockPair(
                                  secondaryLabel: l10n.haggleNewPrice,
                                  onSecondary: () => _haggle.listen(),
                                  primaryLabel: l10n.saveToTrip,
                                  onPrimary: _saveToTrip,
                                ))
                        : DockPair(
                            secondaryLabel: l10n.speakEnterPrice,
                            onSecondary: _enterPrice,
                            primaryIcon: listening
                                ? Icons.stop_rounded
                                : Icons.mic_rounded,
                            primaryLabel: switch (state.phase) {
                              HagglePhase.listening => l10n.speakStop,
                              HagglePhase.preparing => l10n.speakPreparing,
                              _ => l10n.speakListenAgain,
                            },
                            onPrimary: switch (state.phase) {
                              HagglePhase.listening => _haggle.stopListening,
                              HagglePhase.done => () => _haggle.listen(),
                              _ => null,
                            },
                          ),
                },
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
        return [
          _ListeningHero(
            state: state,
            hearingReply: _haggle.hearingReply,
            wordsAfter: _haggle.wordsAfterSentence,
            reading: _haggle.readingSentence,
            // Not "Listening" until the microphone really is.
            preparing: _haggle.wordsAfterSentence && !_haggle.micReady,
          ),
        ];
      case HagglePhase.unavailable:
      case HagglePhase.denied:
        return [
          state.phase == HagglePhase.denied
              ? _Message(
                  title: l10n.speakDeniedTitle,
                  body: l10n.speakDeniedBody,
                )
              : _Message(
                  title: l10n.speakUnavailableTitle,
                  body: l10n.speakUnavailableBody,
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
      // Which engine heard the sentence, measured on this phone.
      if (_haggle.heardTrace case final heardBy? when !state.typed)
        GroupFooter(
          l10n.aiHeardBy(heardBy.engine.displayName, heardBy.elapsedLabel),
        ),
      ?_aiMatchLine(l10n, state),
    ];

    // An item outside the list without a sourced range yet.
    if (heard != null && _haggle.newItem != null && state.match == null) {
      return _newItemContent(l10n, state, heard, _haggle.newItem!, saidSection);
    }

    if (heard != null && state.problem == HeardProblem.unknownItem) {
      // The price came through but not the item: offer the items sold in
      // the heard unit, so one tap finishes the check.
      final unit = heard.unit;
      final options = [
        for (final s in _haggle.items)
          if (unit == null || s.item.unit == unit) s,
      ];
      final suggestion = _haggle.suggestion;
      return [
        _Message(
          title: suggestion == null
              ? l10n.speakWhichItem
              : l10n.haggleDidTheyMean(suggestion.item.nameEn),
          body: l10n.speakHeardPrice(_meaning(l10n, heard, null)),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (suggestion != null) ...[
          Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  label: l10n.haggleNo,
                  onPressed: () => _haggle.acceptSuggestion(false),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton.green(
                  label: l10n.haggleYes,
                  onPressed: () => _haggle.acceptSuggestion(true),
                ),
              ),
            ],
          ),
          if (_haggle.itemGuessTrace case final t?)
            GroupFooter(
              l10n.aiNewItemLine(t.engine.displayName, t.elapsedLabel),
            ),
        ] else
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
              // Not on our list: the traveler names it.
              _ItemChip(
                label: l10n.haggleSomethingElse,
                selected: false,
                onPressed: () => _typeItem(heard.amount),
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
    // What the traveler's own records say about this item; nothing when
    // there are none.
    final history = pastPurchasesFromSaves(AppScope.of(context).trip.saves);
    final now = DateTime.now();
    final place = _haggle.places?.place.name;
    final paidBefore = priceMemory(item.key, history, now, placeName: place);
    final counter = counterFromHistory(item.key, heard.amount, history, now);
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
      if (offer != null) ..._haggleCards(l10n, state, offer),
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
            child: PriceScale(
              low: item.low,
              high: item.high,
              asked: heard.amount,
              verdict: verdict,
              unit: unit,
              counter: offer,
              lastPaid: paidBefore?.lastPaidThb,
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
          if (counter != null)
            GroupRow(
              title: l10n.memoryCounterRow,
              subtitle: _recordsBasis(
                l10n,
                counter.recordsUsed,
                counter.sampleRecords,
              ),
              // The traveler's usual discount, not a second price: the
              // counter-offer above stays the one to say.
              value: l10n.memoryDiscount(
                NumberFormat.decimalPattern('en')
                    .format(counter.medianDiscountPercent.round()),
              ),
            ),
        ],
      ),
      if (_haggle.reference case final ref?
          when match.item.key.startsWith('new:'))
        ..._webReference(l10n, ref)
      else
        GroupFooter(_sourcesLine(l10n, match)),
      if (paidBefore != null)
        GroupFooter(_paidBeforeLine(l10n, paidBefore, place)),
      // It words the first verdict; once the haggle moves on it would be
      // about an old offer.
      if (_explained case (final sentence, final trace)?
          when _haggle.exchanges.isEmpty) ...[
        const SizedBox(height: AppSpacing.groupGap),
        GroupCard(
          children: [
            GroupRow(
              title: sentence,
              subtitle: l10n.aiWordedBy(
                trace.engine.displayName,
                trace.elapsedLabel,
              ),
            ),
          ],
        ),
      ],
      if (_haggle.places case final places?)
        GroupFooter(
          l10n.aiPlacesLine(
            places.trace.engine.displayName,
            places.place.name,
            NumberFormat.decimalPatternDigits(
              locale: 'en',
              decimalDigits: 1,
            ).format(places.place.rating),
            NumberFormat.decimalPattern('en').format(places.place.ratingCount),
            places.trace.elapsedLabel,
          ),
        ),
      ...saidSection,
    ];
  }

  /// The counter-offer card, then (after the seller answered) the next
  /// move: a new offer, the deal, or the seller's last price. Below it, one
  /// tap to say what the seller answered, and the haggle so far.
  List<Widget> _haggleCards(
    AppLocalizations l10n,
    HaggleState state,
    double firstOffer,
  ) {
    final settings = AppScope.of(context).settings;
    final ask = endingText(l10n, settings.politeEnding);
    final say = statementEndingText(l10n, settings.politeEnding);
    final exchanges = _haggle.exchanges;
    final move = exchanges.isEmpty ? null : exchanges.last.move;
    final kind = move?.kind ?? MoveKind.offer;
    final price = AppFormat.roundedNumber(move?.price ?? firstOffer);
    final (label, amount, sentence) = switch (kind) {
      MoveKind.offer => (
        exchanges.isEmpty ? l10n.speakCounterLabel : l10n.haggleNextLabel,
        l10n.speakCounterAmount(price),
        l10n.counterOfferSentence(price, ask),
      ),
      MoveKind.accept => (
        l10n.haggleDealLabel,
        l10n.haggleDealAmount(price),
        l10n.haggleAcceptSentence(price, say),
      ),
      MoveKind.stop => (
        l10n.haggleStopLabel,
        l10n.haggleStopAmount(price),
        l10n.haggleLeaveSentence(say),
      ),
    };
    // What the seller reads, and its meaning for the traveler (a Thai
    // screen needs no translation).
    final thaiScreen = Localizations.localeOf(context).languageCode == 'th';
    final (sellerAmount, meaning) = switch (kind) {
      MoveKind.offer => (
        l10n.showSellerAmount(price),
        l10n.haggleOfferMeaning(price),
      ),
      MoveKind.accept => (
        l10n.showSellerAmount(price),
        l10n.haggleAcceptMeaning(price),
      ),
      MoveKind.stop => (null, l10n.haggleLeaveMeaning),
    };
    return [
      const SizedBox(height: AppSpacing.zoneGap),
      _PeekingStack(
        phrase: sentence,
        child: _CounterCard(
          label: label,
          amount: amount,
          sentence: sentence,
          sayIt: l10n.speakSayIt,
          speakingLabel: l10n.speakSpeaking,
          noVoice: l10n.speakNoVoice,
          canSpeak: state.canSpeak,
          speaking: state.speaking,
          onSpeak: () => _haggle.speakCounter(sentence),
          showSeller: l10n.haggleShowSeller,
          onShowSeller: () => Navigator.of(context).push(
            PageRouteBuilder<void>(
              transitionDuration: AppMotion.of(context, AppMotion.standard),
              reverseTransitionDuration: AppMotion.of(
                context,
                AppMotion.standard,
              ),
              pageBuilder: (_, _, _) => ShowSellerScreen(
                haggle: _haggle,
                sentence: sentence,
                amount: sellerAmount,
                meaning: thaiScreen ? null : meaning,
              ),
              transitionsBuilder: (_, animation, _, child) =>
                  FadeTransition(opacity: animation, child: child),
            ),
          ),
        ),
      ),
      if (_haggle.voiceTrace case final voice?)
        GroupFooter(
          voice.elapsed == Duration.zero
              ? l10n.aiVoiceCached(voice.engine.displayName)
              : l10n.aiTrace(voice.engine.displayName, voice.elapsedLabel),
        ),
      if (exchanges.isNotEmpty) ...[
        SectionHeader(l10n.haggleSoFar),
        GroupCard(
          children: [
            GroupRow(
              title: l10n.haggleFirstAsk,
              value: AppFormat.roundedAmount(
                _haggle.history!.firstAsk,
                marketCurrency,
              ),
            ),
            GroupRow(
              title: l10n.haggleYouOffered,
              value: AppFormat.roundedAmount(firstOffer, marketCurrency),
            ),
            for (final e in exchanges) _exchangeRow(l10n, e),
          ],
        ),
      ],
    ];
  }

  Widget _exchangeRow(AppLocalizations l10n, HaggleExchange e) {
    String money(double? v) => AppFormat.roundedAmount(v ?? 0, marketCurrency);
    final title = switch (e.reply.kind) {
      ReplyKind.accept => l10n.haggleTheyAgreed,
      ReplyKind.refuse => l10n.haggleTheySaidNo,
      ReplyKind.counter => l10n.haggleTheyOfferedPrice(money(e.reply.amount)),
      ReplyKind.unclear => l10n.haggleUnclear,
    };
    final value = switch (e.move.kind) {
      MoveKind.offer => l10n.haggleYouAsk(money(e.move.price)),
      MoveKind.accept => l10n.haggleDealAmount(
        AppFormat.roundedNumber(e.move.price ?? 0),
      ),
      MoveKind.stop => l10n.haggleTheirLast(money(e.move.price)),
    };
    return GroupRow(
      title: title,
      subtitle: e.words.isEmpty ? null : e.words,
      value: value,
    );
  }

  /// The seller named a new price but the market is too loud to hear it.
  Future<void> _enterSellerPrice() async {
    final l10n = AppLocalizations.of(context);
    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PaidSheet(
        asked: maxPriceThb,
        offer: null,
        title: l10n.haggleTheyOfferedTitle,
        action: l10n.haggleUsePrice,
        showKept: false,
      ),
    );
    if (amount != null) {
      _haggle.replyByHand(SellerReply(ReplyKind.counter, amount));
    }
  }

  /// What the on-device AI did, when it named the item in this sentence.
  Widget? _aiMatchLine(AppLocalizations l10n, HaggleState state) {
    final match = _haggle.aiMatch;
    final trace = _haggle.aiMatchTrace;
    if (match == null || trace == null) return null;
    if (_haggle.aiMatchWords != state.words) return null;
    return GroupFooter(
      l10n.aiItemMatched(
        trace.engine.displayName,
        match.item.nameEn,
        NumberFormat.percentPattern('en').format(match.confidence),
        trace.elapsedLabel,
      ),
    );
  }

  /// What the seller answered, one tap each. Lives in the dock while an
  /// offer is on the table, so it is never hidden under it.
  Widget _replyChips(AppLocalizations l10n) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    alignment: WrapAlignment.center,
    children: [
      _ItemChip(
        label: l10n.haggleTheyAgreed,
        selected: false,
        onPressed: () =>
            _haggle.replyByHand(const SellerReply(ReplyKind.accept)),
      ),
      _ItemChip(
        label: l10n.haggleTheySaidNo,
        selected: false,
        onPressed: () =>
            _haggle.replyByHand(const SellerReply(ReplyKind.refuse)),
      ),
      _ItemChip(
        label: l10n.haggleTheyOffered,
        selected: false,
        onPressed: _enterSellerPrice,
      ),
    ],
  );

  /// A counter-offer for an item without a sourced range: the traveler's
  /// own discount on this item, else their usual discount on any item.
  /// Null without any such record.
  CounterFromHistory? _newItemCounter(HaggleState state) {
    final item = _haggle.newItem;
    final heard = state.heard;
    if (item == null || heard == null) return null;
    return counterForNewItem(
      item.key,
      heard.amount,
      pastPurchasesFromSaves(AppScope.of(context).trip.saves),
      DateTime.now(),
    );
  }

  List<Widget> _newItemContent(
    AppLocalizations l10n,
    HaggleState state,
    HeardPrice heard,
    NewItem item,
    List<Widget> saidSection,
  ) {
    final settings = AppScope.of(context).settings;
    final ask = endingText(l10n, settings.politeEnding);
    final counter = _newItemCounter(state);
    final thai = Localizations.localeOf(context).languageCode == 'th';
    final name = thai || item.nameEn == item.nameTh
        ? item.nameTh
        : '${item.nameEn} · ${item.nameTh}';
    final amount = AppFormat.roundedAmount(heard.amount, marketCurrency);
    return [
      _Message(
        title: l10n.haggleNewItemHeard(
          name,
          amount,
          _unitLabel(l10n, heard.unit ?? item.unit),
        ),
        body: _haggle.checkingPrices
            ? l10n.haggleCheckingPrices
            : l10n.haggleNoRange,
      ),
      if (_haggle.itemGuessTrace case final t?)
        GroupFooter(l10n.aiNewItemLine(t.engine.displayName, t.elapsedLabel)),
      if (counter != null) ...[
        const SizedBox(height: AppSpacing.zoneGap),
        Builder(
          builder: (context) {
            final price = AppFormat.roundedNumber(counter.offerThb);
            final sentence = l10n.counterOfferSentence(price, ask);
            return _CounterCard(
              label: l10n.speakCounterLabel,
              amount: l10n.speakCounterAmount(price),
              sentence: sentence,
              sayIt: l10n.speakSayIt,
              speakingLabel: l10n.speakSpeaking,
              noVoice: l10n.speakNoVoice,
              canSpeak: state.canSpeak,
              speaking: state.speaking,
              onSpeak: () => _haggle.speakCounter(sentence),
              showSeller: l10n.haggleShowSeller,
              onShowSeller: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ShowSellerScreen(
                    haggle: _haggle,
                    sentence: sentence,
                    amount: l10n.showSellerAmount(price),
                    meaning: thai ? null : l10n.haggleOfferMeaning(price),
                  ),
                ),
              ),
            );
          },
        ),
        GroupCard(
          children: [
            GroupRow(
              title: l10n.haggleUsualDiscountRow,
              subtitle: _recordsBasis(
                l10n,
                counter.recordsUsed,
                counter.sampleRecords,
              ),
              value: l10n.memoryDiscount(
                NumberFormat.decimalPattern('en')
                    .format(counter.medianDiscountPercent.round()),
              ),
            ),
          ],
        ),
      ],
      ...saidSection,
    ];
  }

  /// A range found on the web: marked "about", each page's own words, its
  /// site and the date it was read.
  List<Widget> _webReference(AppLocalizations l10n, PriceReference ref) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    String day(String date) {
      final d = DateTime.tryParse(date);
      return d == null ? date : DateFormat.yMMMd(locale).format(d);
    }

    return [
      GroupFooter(
        l10n.haggleWebRange(
          AppFormat.roundedNumber(ref.lowThb),
          AppFormat.roundedNumber(ref.highThb),
          ref.sources.length,
        ),
      ),
      for (final q in ref.sources)
        GroupFooter(
          l10n.haggleWebQuote(
            q.quote,
            Uri.parse(q.url).host.replaceFirst('www.', ''),
            q.fetched ? l10n.haggleReadOn(day(q.date)) : day(q.date),
          ),
        ),
      GroupFooter(
        l10n.aiTrace(ref.trace.engine.displayName, ref.trace.elapsedLabel),
      ),
    ];
  }

  /// "Something else": the traveler types the item and the price.
  Future<void> _typeItem(double heardAmount) async {
    final l10n = AppLocalizations.of(context);
    final name = TextEditingController();
    final price = TextEditingController(
      text: AppFormat.roundedNumber(heardAmount).replaceAll(',', ''),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.haggleTypeItem),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: InputDecoration(hintText: l10n.haggleTypeItemHint),
            ),
            TextField(
              controller: price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(suffixText: marketCurrency),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.authCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.speakTypeSubmit),
          ),
        ],
      ),
    );
    final amount = double.tryParse(price.text.trim());
    if (ok == true && amount != null) _haggle.useTypedItem(name.text, amount);
    name.dispose();
    price.dispose();
  }

  /// "You paid 90 THB here 2 days ago · from your 2 past records".
  static String _paidBeforeLine(
    AppLocalizations l10n,
    PriceMemory memory,
    String? placeNow,
  ) {
    final amount = AppFormat.roundedAmount(memory.lastPaidThb, marketCurrency);
    final when = l10n.memoryDaysAgo(memory.daysAgo);
    final last = memory.lastPlaceName;
    final fact = switch (last) {
      null => l10n.memoryPaid(amount, when),
      _ when last == placeNow => l10n.memoryPaidHere(amount, when),
      _ => l10n.memoryPaidAt(amount, last, when),
    };
    return l10n.memoryLine(
      fact,
      _recordsBasis(l10n, memory.recordsUsed, memory.sampleRecords),
    );
  }

  /// How many records a personal line used; demo samples say so.
  static String _recordsBasis(AppLocalizations l10n, int count, int samples) {
    if (samples == 0) return l10n.memoryFromRecords(count);
    if (samples == count) return l10n.memoryFromSamples(count);
    return l10n.memoryFromMixed(count, samples);
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
      return unit == null
          ? amount
          : l10n.speakAmountUnit(amount, _unitLabel(l10n, unit));
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
  const _ListeningHero({
    required this.state,
    this.hearingReply = false,
    this.wordsAfter = false,
    this.reading = false,
    this.preparing = false,
  });

  /// The microphone is still opening.
  final bool preparing;

  /// Cloud path: no live words; they come when the seller has finished.
  final bool wordsAfter;

  /// The cloud is reading the recorded sentence.
  final bool reading;

  final HaggleState state;

  /// Listening to the seller's answer to our offer, not to a first price.
  final bool hearingReply;

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
          widget.state.phase == HagglePhase.preparing || widget.preparing
              ? l10n.speakPreparing
              : widget.hearingReply
              ? l10n.haggleListeningAnswer
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
              ? Column(
                  key: ValueKey(widget.reading ? 'reading' : 'hint'),
                  children: [
                    Text(
                      widget.reading ? l10n.speakReading : l10n.speakListenHint,
                      textAlign: TextAlign.center,
                      style: type.title.copyWith(
                        color: AppColors.onSurfaceTertiary,
                      ),
                    ),
                    if (widget.wordsAfter && !widget.reading) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.speakWordsAfter,
                        textAlign: TextAlign.center,
                        style: type.bodyMd.copyWith(
                          color: AppColors.onSurfaceTertiary,
                        ),
                      ),
                    ],
                  ],
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
            Pill(label: verdictLabel, fill: chipFill, textColor: chipText),
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
    required this.showSeller,
    required this.onShowSeller,
  });

  final String label;
  final String amount;
  final String sentence;
  final String showSeller;
  final VoidCallback onShowSeller;
  final String sayIt;
  final String speakingLabel;
  final String noVoice;
  final bool canSpeak;
  final bool speaking;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    final type = AppTypography.of(context);
    return Surface(
      radius: AppRadius.xl,
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.surfaceDarkTop, AppColors.surfaceDark],
      ),
      shadows: AppElevation.e1,
      edgeLight: EdgeLights.onDark,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
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
            _BreatheOnce(
              key: ValueKey(sentence),
              child: AppButton.green(
                label: speaking ? speakingLabel : sayIt,
                icon: speaking
                    ? Icons.graphic_eq_rounded
                    : Icons.volume_up_rounded,
                busy: speaking,
                onPressed: onSpeak,
              ),
            )
          else
            Text(
              noVoice,
              style: type.bodyMd.copyWith(
                color: AppColors.onSurfaceDarkSecondary,
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          // Too loud to be heard: the words, large, for the seller to read.
          AppButton.secondary(
            label: showSeller,
            icon: Icons.open_in_full_rounded,
            onPressed: onShowSeller,
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
    if (amount > maxPriceThb) return;
    Navigator.of(context).pop((item, amount));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    final amount = _amount;
    final typed = _price.text.isNotEmpty;
    final validPrice = amount != null && amount > 0 && amount <= maxPriceThb;
    final ready = _item != null && validPrice;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.sheetPadding,
          0,
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
            Surface(
              radius: AppRadius.sm,
              color: AppColors.surfaceSunken,
              child: TextField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  LengthLimitingTextInputFormatter(maxPriceChars),
                ],
                style: type.title,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  suffixText: marketCurrency,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
            ),
            if (typed && !validPrice) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                amount == null || amount <= 0
                    ? l10n.speakPriceInvalid
                    : l10n.speakPriceTooHigh(
                        AppFormat.roundedAmount(maxPriceThb, marketCurrency),
                      ),
                style: type.caption.copyWith(color: AppColors.errorText),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: l10n.speakTypeSubmit,
              onPressed: ready ? _submit : null,
            ),
          ],
        ),
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
      child: IntrinsicWidth(
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
      ),
    );
  }
}

/// What the traveler finally paid. Starts at the counter-offer; the two
/// prices said in the haggle are one tap away.
class _PaidSheet extends StatefulWidget {
  const _PaidSheet({
    required this.asked,
    required this.offer,
    this.title,
    this.action,
    this.showKept = true,
  });

  /// The seller's first price; what was paid must be below it to keep
  /// anything. Without [showKept] it is only the upper limit of the field.
  final double asked;
  final double? offer;

  /// Defaults to "What did you pay?" and "Save to trip".
  final String? title;
  final String? action;

  /// False when the sheet only asks for a price (the seller's new one).
  final bool showKept;

  @override
  State<_PaidSheet> createState() => _PaidSheetState();
}

class _PaidSheetState extends State<_PaidSheet> {
  late final _price = TextEditingController(
    text: widget.showKept
        ? AppFormat.roundedNumber(widget.offer ?? widget.asked)
        : '',
  );

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

  double? get _paid => double.tryParse(_price.text.replaceAll(',', ''));

  bool get _valid {
    final paid = _paid;
    if (paid == null || paid <= 0) return false;
    if (!widget.showKept) return paid <= widget.asked;
    // Paying the asked price keeps nothing, so there is nothing to save.
    return paid < widget.asked;
  }

  String _problem(AppLocalizations l10n) {
    final paid = _paid;
    if (paid == null || paid <= 0) return l10n.speakPriceInvalid;
    if (!widget.showKept) {
      return l10n.speakPriceTooHigh(
        AppFormat.roundedAmount(widget.asked, marketCurrency),
      );
    }
    if (paid == widget.asked) return l10n.haggleSaveNothingKept;
    return l10n.haggleSaveTooHigh(
      AppFormat.roundedAmount(widget.asked, marketCurrency),
    );
  }

  void _set(double value) {
    final text = AppFormat.roundedNumber(value);
    _price.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    final offer = widget.offer;
    final paid = _paid;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.sheetPadding,
          0,
          AppSpacing.sheetPadding,
          AppSpacing.sheetPadding + insets,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title ?? l10n.haggleSaveTitle, style: type.title),
            const SizedBox(height: AppSpacing.xl),
            if (widget.showKept)
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  if (offer != null)
                    _ItemChip(
                      label: l10n.haggleSaveChoice(
                        l10n.haggleSaveOffer,
                        AppFormat.roundedAmount(offer, marketCurrency),
                      ),
                      selected: paid == offer,
                      onPressed: () => _set(offer),
                    ),
                  _ItemChip(
                    label: l10n.haggleSaveChoice(
                      l10n.haggleSaveAsked,
                      AppFormat.roundedAmount(widget.asked, marketCurrency),
                    ),
                    selected: paid == widget.asked,
                    onPressed: () => _set(widget.asked),
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.lg),
            Surface(
              radius: AppRadius.sm,
              color: AppColors.surfaceSunken,
              child: TextField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  LengthLimitingTextInputFormatter(maxPriceChars),
                ],
                style: type.title,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (_valid) Navigator.of(context).pop(_paid);
                },
                decoration: const InputDecoration(
                  suffixText: marketCurrency,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (widget.showKept || (_price.text.isNotEmpty && !_valid))
              Text(
                _valid
                    ? l10n.haggleSaveKeeps(
                        AppFormat.roundedAmount(
                          haggleKeptThb(askedThb: widget.asked, paidThb: paid!),
                          marketCurrency,
                        ),
                      )
                    : _problem(l10n),
                style: type.caption.copyWith(
                  color: _valid
                      ? AppColors.primaryText
                      : AppColors.onSurfaceTertiary,
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: widget.action ?? l10n.saveToTrip,
              onPressed: _valid ? () => Navigator.of(context).pop(_paid) : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// The counter-offer on top of a small stack of phrase cards, peeking out
/// below it (Apple Wallet style), so the screen reads as "the phrase to
/// use, from the ones you could say". A new phrase (another offer, another
/// polite ending) enters as the top card on a spring. Cards never swipe
/// away: this is money, not a game.
class _PeekingStack extends StatefulWidget {
  const _PeekingStack({required this.phrase, required this.child});

  /// Changes when a new phrase arrives; the top card then enters again.
  final String phrase;
  final Widget child;

  @override
  State<_PeekingStack> createState() => _PeekingStackState();
}

class _PeekingStackState extends State<_PeekingStack>
    with SingleTickerProviderStateMixin {
  late final _enter = AnimationController.unbounded(vsync: this);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _play();
  }

  @override
  void didUpdateWidget(_PeekingStack old) {
    super.didUpdateWidget(old);
    if (old.phrase != widget.phrase) _play();
  }

  void _play() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _enter.value = 1;
      return;
    }
    _enter
      ..value = 0
      ..animateWith(SpringSimulation(AppMotion.cardEnter, 0, 1, 0));
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final depth = AppSizes.stackScales.length;
    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.stackOffsets.last),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = depth - 1; i >= 0; i--)
            Positioned.fill(
              child: ExcludeSemantics(
                child: Transform.translate(
                  offset: Offset(0, AppSizes.stackOffsets[i]),
                  child: Transform.scale(
                    scale: AppSizes.stackScales[i],
                    alignment: Alignment.bottomCenter,
                    child: Opacity(
                      opacity: AppSizes.stackOpacities[i],
                      child: Surface(
                        radius: AppRadius.xl,
                        color: AppColors.stackCard,
                        shadows: AppElevation.e0,
                        edgeLight: EdgeLights.onDark,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          AnimatedBuilder(
            animation: _enter,
            builder: (context, child) {
              final t = _enter.value;
              return Transform.translate(
                offset: Offset(0, (1 - t) * AppSizes.stackEnterRise),
                child: Transform.scale(
                  scale: lerpDouble(AppSizes.stackScales.first, 1, t),
                  alignment: Alignment.bottomCenter,
                  child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
                ),
              );
            },
            // The front card spans the stack, like the cards peeking behind.
            child: SizedBox(width: double.infinity, child: widget.child),
          ),
        ],
      ),
    );
  }
}

/// Grows a touch and settles back once, shortly after it appears: the
/// counter-offer is ready to be said. Never repeats; skipped with reduce
/// motion.
class _BreatheOnce extends StatefulWidget {
  const _BreatheOnce({super.key, required this.child});

  final Widget child;

  @override
  State<_BreatheOnce> createState() => _BreatheOnceState();
}

class _BreatheOnceState extends State<_BreatheOnce>
    with SingleTickerProviderStateMixin {
  late final _breath = AnimationController(
    vsync: this,
    duration: AppMotion.sayItBreath,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || MediaQuery.disableAnimationsOf(context)) return;
    _started = true;
    Future.delayed(AppMotion.sayItBreathDelay, () {
      if (mounted) _breath.forward();
    });
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breath,
      builder: (context, child) => Transform.scale(
        scale:
            1 +
            (AppMotion.sayItBreathScale - 1) *
                math.sin(math.pi * AppMotion.move.transform(_breath.value)),
        child: child,
      ),
      child: widget.child,
    );
  }
}
