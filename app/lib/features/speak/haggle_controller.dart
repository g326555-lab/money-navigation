import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../data/market_price_repository.dart';
import '../../rules/haggle.dart';
import '../../rules/haggle_rounds.dart';
import '../../services/ai/ai_trace.dart';
import '../../services/ai/cloud_functions.dart';
import '../../services/ai/cloud_speech.dart';
import '../../services/ai/gemini_item.dart';
import '../../services/ai/price_reference.dart';
import '../../rules/new_item.dart';
import '../../services/ai/item_matcher.dart';
import '../../services/ai/item_resolver.dart';
import '../../services/clip_recorder.dart';
import '../../services/cloud_voice.dart';
import '../../services/places_service.dart';
import '../../services/speech_service.dart';
import '../../services/tts_service.dart';

enum HagglePhase {
  /// Starting the recognizer and loading prices.
  preparing,

  /// Thai speech recognition is not available on this device.
  unavailable,

  /// Microphone or speech permission was refused.
  denied,
  listening,

  /// Listening ended; showing what was understood.
  done,
}

enum HeardProblem { nothingHeard, noPrice, unknownItem, unitMismatch }

/// One reply from the seller after our offer, and what to do next.
@immutable
class HaggleExchange {
  const HaggleExchange({
    required this.words,
    required this.reply,
    required this.move,
  });

  /// What the seller said, as recognized, or empty when tapped by hand.
  final String words;
  final SellerReply reply;
  final NextMove move;
}

/// Everything the haggling screen shows, built only from real speech text,
/// the sourced price file and the rules.
@immutable
class HaggleState {
  const HaggleState({
    this.phase = HagglePhase.preparing,
    this.words = '',
    this.level = 0,
    this.heard,
    this.match,
    this.verdict,
    this.problem,
    this.speaking = false,
    this.canSpeak = false,
    this.typed = false,
  });

  final HagglePhase phase;

  /// The Thai sentence as recognized (or typed).
  final String words;

  /// Microphone level, normalized 0..1.
  final double level;
  final HeardPrice? heard;
  final SourcedItem? match;
  final HaggleVerdict? verdict;
  final HeardProblem? problem;
  final bool speaking;
  final bool canSpeak;

  /// True when the sentence was typed instead of heard.
  final bool typed;

  HaggleState copyWith({
    HagglePhase? phase,
    String? words,
    double? level,
    bool? speaking,
    bool? canSpeak,
  }) => HaggleState(
    phase: phase ?? this.phase,
    words: words ?? this.words,
    level: level ?? this.level,
    heard: heard,
    match: match,
    verdict: verdict,
    problem: problem,
    speaking: speaking ?? this.speaking,
    canSpeak: canSpeak ?? this.canSpeak,
    typed: typed,
  );
}

class HaggleController extends ChangeNotifier {
  HaggleController({
    SpeechService? speech,
    TtsService? tts,
    MarketPriceRepository? prices,
    ItemResolver? resolver,
    PlacesService? places,
    CloudVoice? voice,
    ClipRecorder? recorder,
    CloudSpeech? cloudSpeech,
    bool? cloudFirst,
    GeminiItemResolver? itemGuesser,
    PriceReferenceService? priceReference,
  }) : _recorderOverride = recorder,
       _priceReference = priceReference ?? PriceReferenceService(),
       _guesser = itemGuesser ?? GeminiItemResolver(),
       _cloudSpeech = cloudSpeech ?? CloudSpeech(),
       _cloudFirst = cloudFirst ?? CloudFunctions.configured,
       _speech = speech ?? SpeechService(),
       _tts = tts ?? TtsService(),
       _prices = prices ?? MarketPriceRepository(),
       _resolver = resolver ?? ItemResolver(),
       _places = places ?? PlacesService(),
       _voice = voice ?? CloudVoice();

  final ItemResolver _resolver;

  /// Gemini names an item the on-device matcher did not know: one of ours
  /// ("Did they mean …?") or a new one, in the seller's own words.
  final GeminiItemResolver _guesser;

  /// A known item Gemini thinks was meant; the traveler confirms it.
  SourcedItem? get suggestion => _suggestion;
  SourcedItem? _suggestion;

  /// An item outside our price list, named from what was heard or typed.
  NewItem? get newItem => _newItem;
  NewItem? _newItem;

  /// A usual price for an item outside our list, looked up on the web
  /// (wholesale pages are filtered out by the service).
  final PriceReferenceService _priceReference;
  PriceReference? get reference => _reference;
  PriceReference? _reference;

  /// True while the web lookup runs; the screen never waits for it.
  bool get checkingPrices => _checkingPrices;
  bool _checkingPrices = false;

  /// How the item was named (Gemini), when it was.
  AiTrace? get itemGuessTrace => _guessTrace;
  AiTrace? _guessTrace;

  /// Cloud recognition hears a seller far better than the phone (15/15
  /// against 9/15 in quiet, 13/15 against 1/15 with market noise), so when
  /// it is configured the sentence is recorded once and sent there; the
  /// phone's own recognizer is the fallback, offline or when the cloud
  /// fails. Android cannot run both on the microphone at once.
  final bool _cloudFirst;
  final CloudSpeech _cloudSpeech;
  final ClipRecorder? _recorderOverride;
  ClipRecorder? _recorderInstance;
  ClipRecorder get _recorder =>
      _recorderOverride ?? (_recorderInstance ??= ClipRecorder());

  /// True while a clip is being recorded for the cloud.
  bool _recording = false;

  /// True while the cloud reads the recorded sentence.
  bool _reading = false;

  /// The words come only after the seller finishes (cloud path): the
  /// listening screen says so instead of showing live words.
  bool get wordsAfterSentence => _recording;

  /// The microphone is delivering audio for the clip.
  bool get micReady => _micOpen;
  bool _micOpen = false;
  bool get readingSentence => _reading;

  /// The cloud failed this screen once; the phone listens from then on.
  bool _cloudFailed = false;

  /// How the last sentence was heard, when the cloud heard it.
  AiTrace? get heardTrace => _heardTrace;
  AiTrace? _heardTrace;

  final PlacesService _places;
  final CloudVoice _voice;

  /// The recognizer's alternatives for the current sentence.
  List<String> _alternatives = const [];

  /// On-device AI naming the item when speech recognition misheard it, for
  /// the sentence in [aiMatchWords]. Measured on this phone.
  ItemMatch? get aiMatch => _aiMatch;
  AiTrace? get aiMatchTrace => _aiMatchTrace;
  String? get aiMatchWords => _aiMatchWords;
  ItemMatch? _aiMatch;
  AiTrace? _aiMatchTrace;
  String? _aiMatchWords;

  /// The haggle after the first verdict: every price said and offered.
  HaggleHistory? get history => _history;
  HaggleHistory? _history;

  /// The seller's replies so far, oldest first.
  List<HaggleExchange> get exchanges => List.unmodifiable(_exchanges);
  final List<HaggleExchange> _exchanges = [];

  /// True while listening to the seller's reply to our offer, not to a new
  /// price.
  bool get hearingReply => _hearingReply;
  bool _hearingReply = false;

  /// The verdict screen to return to after a reply.
  HaggleState? _beforeReply;

  /// The sentence the on-device matcher last ran on.
  String? _resolvingWords;

  /// The busiest rated market nearby on Google Maps, when it arrived.
  PlacesEvidence? get places => _placesEvidence;
  PlacesEvidence? _placesEvidence;

  /// How the last counter-offer was voiced: the cloud voice's measured
  /// step, or null when the phone's own voice spoke.
  AiTrace? get voiceTrace => _voiceTrace;
  AiTrace? _voiceTrace;

  final SpeechService _speech;
  final TtsService _tts;
  final MarketPriceRepository _prices;
  List<SourcedItem> _items = const [];
  HaggleState _state = const HaggleState();
  bool _disposed = false;

  /// When the current listen began; it keeps going until words arrive or
  /// [speechKeepListening] has passed.
  DateTime? _listenStarted;
  bool _restarting = false;

  /// The words of the last listen, to ignore its late final result.
  String _previousWords = '';

  /// Fires when a complete price (item, amount) has been heard and the
  /// words have stopped changing, so the verdict does not wait for the
  /// recognizer's own end-of-speech silence.
  Timer? _settle;

  HaggleState get state => _state;

  Future<void> start() async {
    _set(const HaggleState());
    _items = await _prices.load();
    final canSpeak = await _tts.prepare();
    var denied = false;
    final ok = await _speech.prepare(
      onStatus: _onStatus,
      onError: (SpeechRecognitionError e) {
        if (kDebugMode) debugPrint('[haggle] error=${e.errorMsg}');
        if (_isPermissionError(e.errorMsg)) {
          denied = true;
          _set(HaggleState(phase: HagglePhase.denied, canSpeak: canSpeak));
          return;
        }
        // "No match" and "speech timeout" only mean nobody spoke yet. Some
        // devices report a refused permission only as an unknown error, so
        // check the permission before treating it as silence.
        if (_state.words.isNotEmpty) {
          _finish();
          return;
        }
        _speech.hasPermission.then((granted) {
          if (_disposed) return;
          if (granted) {
            _finish();
          } else {
            _set(HaggleState(phase: HagglePhase.denied, canSpeak: canSpeak));
          }
        });
      },
    );
    if (ok && !await _speech.hasPermission) denied = true;
    // Local evidence arrives on its own; the screen adds it when it lands.
    // Asked after the microphone prompt, so two permission prompts never
    // overlap.
    if (_placesEvidence == null) {
      unawaited(
        _places.nearbyMarket().then((p) {
          if (p == null || _disposed) return;
          _placesEvidence = p;
          notifyListeners();
        }),
      );
    }

    if (!ok || denied) {
      _set(
        HaggleState(
          phase: denied ? HagglePhase.denied : HagglePhase.unavailable,
          canSpeak: canSpeak,
        ),
      );
      return;
    }
    await listen(canSpeak: canSpeak);
  }

  static bool _isPermissionError(String message) =>
      message.contains('permission') || message.contains('denied');

  Future<void> listen({bool? canSpeak}) async {
    _resetHaggle();
    await _tts.stop();
    await _voice.stop();
    // The previous session's last result can arrive after this listen
    // starts; remember its words so that late result is ignored.
    _previousWords = _state.words;
    _alternatives = const [];
    _resolvingWords = null;
    _aiMatch = null;
    _aiMatchTrace = null;
    _aiMatchWords = null;
    _voiceTrace = null;
    _heardTrace = null;
    _clearGuess();
    _set(
      HaggleState(
        phase: HagglePhase.listening,
        canSpeak: canSpeak ?? _state.canSpeak,
      ),
    );
    _listenStarted = DateTime.now();
    await _listenOnce();
  }

  /// One sentence: through the cloud when it can, else the phone.
  Future<void> _listenOnce() async {
    if (_cloudFirst && !_cloudFailed) {
      await _listenCloud();
    } else {
      await _startSession();
    }
  }

  List<String> get _hints => [
    for (final s in _items) ...s.item.keywordsTh,
    ...pricePhrasesTh,
  ];

  /// Records the seller's sentence and has the cloud read it. Nothing
  /// recorded (silence, no permission) or a cloud failure hands over to the
  /// phone's recognizer, which keeps listening.
  Future<void> _listenCloud() async {
    // Two captures on one microphone: the later one gets silence (Android),
    // and stopping the recognizer ends the audio session (iOS).
    if (_speech.isListening) await _speech.cancel();
    Uint8List? clip;
    while (true) {
      _recording = true;
      _micOpen = false;
      notifyListeners();
      try {
        clip = await _recorder.record(
          // "Listening" only once the microphone really delivers audio, or
          // the seller's first word is lost.
          onStarted: () {
            _micOpen = true;
            notifyListeners();
          },
          onLevel: (level) {
            if (_state.phase == HagglePhase.listening) {
              _set(_state.copyWith(level: level));
            }
          },
        );
      } finally {
        _recording = false;
        _micOpen = false;
      }
      if (_disposed || _state.phase != HagglePhase.listening) return;
      // Nobody spoke yet: the seller is thinking. Keep listening the same
      // way, as the phone's recognizer does, up to the same limit.
      final started = _listenStarted;
      final silence =
          clip == null && _recorder.lastOutcome == ClipOutcome.silence;
      if (!silence) break;
      if (started != null &&
          DateTime.now().difference(started) >= speechKeepListening) {
        unawaited(_tts.restoreSpeaker());
        if (_hearingReply) {
          _applyReply('', classifyReply(''));
        } else {
          _understand('', typed: false, phase: HagglePhase.done);
        }
        return;
      }
    }
    // Recording takes the audio session over on iOS; give the voice its
    // speaker back before anything is said.
    unawaited(_tts.restoreSpeaker());
    _reading = clip != null;
    notifyListeners();
    final heard = clip == null
        ? null
        : await _cloudSpeech.recognize(
            clip,
            sampleRateHertz: ClipRecorder.sampleRate,
            phrases: _hints,
          );
    _reading = false;
    if (_disposed || _state.phase != HagglePhase.listening) return;
    if (heard == null) {
      if (kDebugMode) debugPrint('[haggle] cloud gave nothing, phone listens');
      _cloudFailed = true;
      await _startSession();
      return;
    }
    final (transcripts, trace) = heard;
    _heardTrace = trace;
    if (kDebugMode) {
      debugPrint('[haggle] cloud ${trace.elapsedLabel} heard=$transcripts');
    }
    if (_hearingReply) {
      final words = transcripts.first;
      _applyReply(words, classifyReply(words));
      return;
    }
    // The first transcript that names an item and a price, else the best.
    final items = [for (final s in _items) s.item];
    final words = transcripts.firstWhere(
      (t) => parseHeardPrice(t, items)?.item != null,
      orElse: () => transcripts.first,
    );
    _alternatives = transcripts;
    _understand(words, typed: false, phase: HagglePhase.done);
  }

  /// Listens to the seller's answer to our offer: yes, no, or a new price.
  /// The verdict stays as it is; the answer moves the haggle on.
  Future<void> listenForReply() async {
    final base = _state;
    if (!_ensureHistory(base)) return;
    await _tts.stop();
    await _voice.stop();
    _hearingReply = true;
    _beforeReply = base;
    _previousWords = base.words;
    _set(HaggleState(phase: HagglePhase.listening, canSpeak: base.canSpeak));
    _listenStarted = DateTime.now();
    await _listenOnce();
  }

  /// For a loud market: the traveler taps what the seller answered.
  void replyByHand(SellerReply reply) {
    if (!_ensureHistory(_state)) return;
    _beforeReply ??= _state;
    _applyReply('', reply);
  }

  void _clearGuess() {
    _suggestion = null;
    _newItem = null;
    _guessTrace = null;
    _reference = null;
    _checkingPrices = false;
  }

  /// Looks the new item up on the web. With a sourced range it becomes an
  /// item like ours and gets a verdict; without one the screen keeps
  /// saying there is no sourced range.
  Future<void> _lookUpPrice(NewItem item) async {
    _checkingPrices = true;
    notifyListeners();
    var ref = await _priceReference.lookup(item.nameEn);
    if (_disposed || !identical(_newItem, item)) return;
    _checkingPrices = false;
    _reference = ref;
    final heard = _state.heard;
    // The haggle moved on (a reply came, a new listen began): leave it.
    if (_exchanges.isNotEmpty || _state.phase != HagglePhase.done) {
      ref = null;
    }
    if (ref == null || heard == null || ref.sources.isEmpty) {
      notifyListeners();
      return;
    }
    final unit = heard.unit ?? item.unit;
    final market = MarketItem(
      key: item.key,
      nameEn: item.nameEn,
      nameTh: item.nameTh,
      keywordsTh: [item.nameTh],
      unit: unit,
      low: ref.lowThb,
      high: ref.highThb,
    );
    final sourced = SourcedItem(
      item: market,
      sources: [
        for (final q in ref.sources)
          PriceSource(title: Uri.parse(q.url).host, url: q.url, date: q.date),
      ],
    );
    final withItem = HeardPrice(amount: heard.amount, item: market, unit: unit);
    final verdict = judgePrice(withItem, market);
    _set(
      HaggleState(
        phase: _state.phase,
        words: _state.words,
        heard: withItem,
        match: sourced,
        verdict: verdict,
        problem: verdict == null ? HeardProblem.unitMismatch : null,
        canSpeak: _state.canSpeak,
        speaking: _state.speaking,
        typed: _state.typed,
      ),
    );
  }

  /// "Did they mean …?" answered: yes takes the suggested item.
  void acceptSuggestion(bool yes) {
    final s = _suggestion;
    _suggestion = null;
    if (yes && s != null) {
      chooseItem(s);
    } else {
      notifyListeners();
    }
  }

  /// An item typed by the traveler that is not on our list.
  void useTypedItem(String name, double amount) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || amount <= 0) return;
    // Keep the unit the seller said (per kilo, a plate); "each" only when
    // none was heard.
    final unit = _state.heard?.unit ?? PriceUnit.each;
    _resetHaggle();
    _clearGuess();
    _newItem = NewItem(
      nameTh: trimmed,
      nameEn: trimmed,
      unit: unit,
      category: ItemCategory.other,
    );
    _set(
      HaggleState(
        phase: HagglePhase.done,
        heard: HeardPrice(amount: amount, unit: unit),
        problem: HeardProblem.unknownItem,
        canSpeak: _state.canSpeak,
        typed: true,
      ),
    );
    unawaited(_lookUpPrice(_newItem!));
  }

  void _resetHaggle() {
    _history = null;
    _exchanges.clear();
    _hearingReply = false;
    _beforeReply = null;
  }

  bool _ensureHistory(HaggleState base) {
    final heard = base.heard;
    final match = base.match;
    final offer = base.verdict?.counterOffer;
    if (heard == null || match == null || offer == null) return false;
    _history ??= HaggleHistory(
      item: match.item,
      firstAsk: heard.amount,
      firstOffer: offer,
    );
    return true;
  }

  void _applyReply(String words, SellerReply reply) {
    final history = _history;
    final base = _beforeReply;
    if (history == null || base == null) return;
    final move = history.respond(reply);
    _exchanges.add(HaggleExchange(words: words, reply: reply, move: move));
    _hearingReply = false;
    if (kDebugMode) {
      debugPrint(
        '[haggle] reply words="$words" kind=${reply.kind.name} '
        'amount=${reply.amount} move=${move.kind.name} price=${move.price}',
      );
    }
    _set(base.copyWith(phase: HagglePhase.done, speaking: false));
  }

  /// One recognizer session. The platform ends a session after a short
  /// silence, even before anyone has spoken; [_finish] starts a new one
  /// until words arrive, so the app keeps listening while the seller thinks.
  Future<void> _startSession() async {
    await _speech.listen(
      phrases: [
        for (final s in _items) ...s.item.keywordsTh,
        ...pricePhrasesTh,
      ],
      onLevel: (level) => _set(_state.copyWith(level: _normalize(level))),
      onWords: (words, isFinal, alternatives) {
        if (kDebugMode) debugPrint('[haggle] partial="$words" final=$isFinal');
        if (_state.phase != HagglePhase.listening) return;
        // The previous sentence coming back is that session's late result.
        final stale = words.isNotEmpty && words == _previousWords;
        if (stale) return;
        if (_state.words.isEmpty && words.isNotEmpty) _speech.speechStarted();
        if (_hearingReply) {
          _set(_state.copyWith(words: words));
          _settle?.cancel();
          if (isFinal) {
            _finish();
          } else if (classifyReply(words).kind != ReplyKind.unclear) {
            _settle = Timer(speechSettleAfterPrice, stopListening);
          }
          return;
        }
        _alternatives = alternatives.isEmpty ? [words] : alternatives;
        _understand(words, typed: false, phase: _state.phase);
        _settle?.cancel();
        if (isFinal) {
          _finish();
        } else if (_state.heard?.unit != null || _state.verdict != null) {
          // Amount and unit are enough to move on: either the verdict, or
          // one tap to name the item.
          _settle = Timer(speechSettleAfterPrice, stopListening);
        }
      },
    );
  }

  /// The seller's price was heard but not the item: the user names it with
  /// one tap and the heard amount and unit are kept.
  void chooseItem(SourcedItem match) {
    _resetHaggle();
    _clearGuess();
    final heard = _state.heard;
    if (heard == null) return;
    final withItem = HeardPrice(
      amount: heard.amount,
      item: match.item,
      unit: heard.unit,
    );
    final verdict = judgePrice(withItem, match.item);
    _set(
      HaggleState(
        phase: HagglePhase.done,
        words: _state.words,
        heard: withItem,
        match: match,
        verdict: verdict,
        problem: verdict == null ? HeardProblem.unitMismatch : null,
        canSpeak: _state.canSpeak,
        typed: _state.typed,
      ),
    );
  }

  /// The items with sourced prices, for picking one by hand.
  List<SourcedItem> get items => _items;

  /// Uses an item and price entered by hand, for when the market is too
  /// loud to hear. A visitor can't type Thai, so this skips speech text.
  Future<void> submitManual(SourcedItem match, double amount) async {
    _resetHaggle();
    _clearGuess();
    if (_speech.isListening) await _speech.cancel();
    if (_recording) await _recorder.stop();
    final heard = HeardPrice(
      amount: amount,
      item: match.item,
      unit: match.item.unit,
    );
    _set(
      HaggleState(
        phase: HagglePhase.done,
        heard: heard,
        match: match,
        verdict: judgePrice(heard, match.item),
        canSpeak: _state.canSpeak,
        typed: true,
      ),
    );
  }

  Future<void> stopListening() async {
    _settle?.cancel();
    // "Done" while recording: the cloud gets what was said so far.
    if (_recording) {
      await _recorder.stop();
      return;
    }
    await _speech.stop();
    _finish(byUser: true);
  }

  Future<void> speakCounter(String sentence) async {
    if (!_state.canSpeak || _state.speaking) return;
    _set(_state.copyWith(speaking: true));
    try {
      // The natural cloud voice first; the phone's voice when it is not
      // configured, offline or slow.
      final cloud = await _voice.speak(sentence);
      _voiceTrace = cloud;
      if (cloud == null) await _tts.speak(sentence);
    } finally {
      _set(_state.copyWith(speaking: false));
    }
  }

  void _onStatus(String status) {
    if (kDebugMode) debugPrint('[haggle] status=$status');
    if (status == SpeechToText.doneStatus ||
        status == SpeechToText.notListeningStatus) {
      _finish();
    }
  }

  void _finish({bool byUser = false}) {
    if (_state.phase != HagglePhase.listening || _restarting) return;
    final started = _listenStarted;
    final stillWaiting =
        !byUser &&
        _state.words.isEmpty &&
        started != null &&
        DateTime.now().difference(started) < speechKeepListening;
    if (stillWaiting) {
      _restart();
      return;
    }
    if (_hearingReply) {
      _applyReply(_state.words, classifyReply(_state.words));
      return;
    }
    _understand(_state.words, typed: _state.typed, phase: HagglePhase.done);
  }

  Future<void> _restart() async {
    _restarting = true;
    await Future<void>.delayed(speechRestartDelay);
    _restarting = false;
    if (_disposed || _state.phase != HagglePhase.listening) return;
    if (_speech.isListening) return;
    await _startSession();
  }

  /// Runs the rules on the current sentence. Called on every partial result,
  /// so the verdict appears as soon as the price has been said.
  void _understand(
    String words, {
    required bool typed,
    required HagglePhase phase,
  }) {
    var heard = parseHeardPrice(words, [for (final s in _items) s.item]);
    // The on-device AI already named the item in this very sentence.
    final ai = _aiMatch;
    if (heard != null &&
        heard.item == null &&
        ai != null &&
        _aiMatchWords == words) {
      heard = HeardPrice(amount: heard.amount, item: ai.item, unit: heard.unit);
    }
    SourcedItem? match;
    HaggleVerdict? verdict;
    HeardProblem? problem;
    if (words.isEmpty) {
      problem = HeardProblem.nothingHeard;
    } else if (heard == null) {
      problem = HeardProblem.noPrice;
    } else if (heard.item == null) {
      problem = HeardProblem.unknownItem;
      if (!typed) _resolveItem(words, heard, phase);
    } else {
      final key = heard.item!.key;
      match = _items.firstWhere((s) => s.item.key == key);
      verdict = judgePrice(heard, match.item);
      if (verdict == null) problem = HeardProblem.unitMismatch;
    }
    if (kDebugMode && phase == HagglePhase.done) {
      // What speech recognition heard, to measure it on a real device.
      debugPrint(
        '[haggle] done words="$words" amount=${heard?.amount} '
        'item=${heard?.item?.key} unit=${heard?.unit?.name} '
        'verdict=${verdict?.verdict.name} problem=${problem?.name}',
      );
    }
    _set(
      HaggleState(
        phase: phase,
        words: words,
        level: phase == HagglePhase.listening ? _state.level : 0,
        heard: heard,
        match: match,
        verdict: verdict,
        problem: problem,
        canSpeak: _state.canSpeak,
        typed: typed,
      ),
    );
  }

  /// Asks the on-device matcher which item the seller named, using every
  /// transcript the recognizer considered. When it is sure enough, the
  /// verdict appears as if the item had been heard; otherwise the screen
  /// keeps offering the item buttons.
  Future<void> _resolveItem(
    String words,
    HeardPrice heard,
    HagglePhase phase,
  ) async {
    // Partial and final results repeat the same sentence; match it once.
    if (_resolvingWords == words) return;
    _resolvingWords = words;
    final alternatives = _alternatives;
    final (match, trace) = await AiTrace.measure(
      AiEngine.onDevice,
      () => _resolver.resolve(alternatives, _items, unit: heard.unit),
    );
    if (_disposed || _state.words != words) return;
    if (match == null) {
      // Not one of ours on the phone: Gemini, with every transcript.
      await _guessItem(words, heard, alternatives);
      return;
    }
    if (_state.problem != HeardProblem.unknownItem) return;
    final sourced = _items.firstWhere((s) => s.item.key == match.item.key);
    final withItem = HeardPrice(
      amount: heard.amount,
      item: match.item,
      unit: heard.unit,
    );
    final verdict = judgePrice(withItem, match.item);
    _aiMatch = match;
    _aiMatchTrace = trace;
    _aiMatchWords = words;
    _set(
      HaggleState(
        phase: _state.phase,
        words: words,
        level: _state.level,
        heard: withItem,
        match: sourced,
        verdict: verdict,
        problem: verdict == null ? HeardProblem.unitMismatch : null,
        canSpeak: _state.canSpeak,
      ),
    );
  }

  Future<void> _guessItem(
    String words,
    HeardPrice heard,
    List<String> alternatives,
  ) async {
    final guess = await _guesser.resolve(
      alternatives.isEmpty ? [words] : alternatives,
      [for (final s in _items) s.item],
      unit: heard.unit,
    );
    if (_disposed || guess == null || _state.words != words) return;
    if (_state.problem != HeardProblem.unknownItem) return;
    _guessTrace = guess.trace;
    final known = guess.known;
    if (known != null) {
      _suggestion = _items.firstWhere((s) => s.item.key == known.key);
    } else {
      _newItem = guess.newItem;
    }
    notifyListeners();
    if (_newItem case final item?) unawaited(_lookUpPrice(item));
  }

  /// speech_to_text reports dB-like levels (about -2..10 on iOS, 0..10 on
  /// Android); the waveform needs 0..1.
  static double _normalize(double level) =>
      ((level - speechLevelFloor) / (speechLevelCeiling - speechLevelFloor))
          .clamp(0.0, 1.0);

  void _set(HaggleState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _settle?.cancel();
    _speech.cancel();
    _recorderInstance?.dispose();
    _tts.stop();
    _voice.dispose();
    super.dispose();
  }
}

/// How long the words must stay unchanged after a full price was heard
/// before the verdict is shown.
const speechSettleAfterPrice = Duration(milliseconds: 800);

/// Longest the app waits for the seller to start speaking.
const speechKeepListening = Duration(seconds: 30);

/// Pause before starting a new recognizer session after one ends unheard.
const speechRestartDelay = Duration(milliseconds: 150);

/// Price words sellers use, as extra hints for the recognizer next to the
/// item names from the data file.
const pricePhrasesTh = [
  'กิโลละ',
  'โลละ',
  'ลูกละ',
  'จานละ',
  'แก้วละ',
  'ชั่วโมงละ',
  'บาท',
  'ร้อย',
  'ห้าสิบ',
];

const speechLevelFloor = -2.0;
const speechLevelCeiling = 10.0;
