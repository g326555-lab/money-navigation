import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../data/market_price_repository.dart';
import '../../rules/haggle.dart';
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
  }) : _speech = speech ?? SpeechService(),
       _tts = tts ?? TtsService(),
       _prices = prices ?? MarketPriceRepository();

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
        // "No match" and "speech timeout" only mean nobody spoke yet.
        _finish();
      },
    );
    if (ok && !await _speech.hasPermission) denied = true;
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
    await _tts.stop();
    // The previous session's last result can arrive after this listen
    // starts; remember its words so that late result is ignored.
    _previousWords = _state.words;
    _set(
      HaggleState(
        phase: HagglePhase.listening,
        canSpeak: canSpeak ?? _state.canSpeak,
      ),
    );
    _listenStarted = DateTime.now();
    await _startSession();
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
      onWords: (words, isFinal) {
        if (kDebugMode) debugPrint('[haggle] partial="$words" final=$isFinal');
        if (_state.phase != HagglePhase.listening) return;
        // The previous sentence coming back is that session's late result.
        final stale = words.isNotEmpty && words == _previousWords;
        if (stale) return;
        if (_state.words.isEmpty && words.isNotEmpty) _speech.speechStarted();
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
    if (_speech.isListening) await _speech.cancel();
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
    await _speech.stop();
    _finish(byUser: true);
  }

  Future<void> speakCounter(String sentence) async {
    if (!_state.canSpeak || _state.speaking) return;
    _set(_state.copyWith(speaking: true));
    try {
      await _tts.speak(sentence);
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
    final heard = parseHeardPrice(words, [for (final s in _items) s.item]);
    SourcedItem? match;
    HaggleVerdict? verdict;
    HeardProblem? problem;
    if (words.isEmpty) {
      problem = HeardProblem.nothingHeard;
    } else if (heard == null) {
      problem = HeardProblem.noPrice;
    } else if (heard.item == null) {
      problem = HeardProblem.unknownItem;
    } else {
      match = _items.firstWhere((s) => s.item.key == heard.item!.key);
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
    _tts.stop();
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
