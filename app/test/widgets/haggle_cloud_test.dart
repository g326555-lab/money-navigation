import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/data/market_price_repository.dart';
import 'package:money_navigation/features/speak/haggle_controller.dart';
import 'package:money_navigation/rules/haggle.dart';
import 'package:money_navigation/rules/haggle_rounds.dart';
import 'package:money_navigation/services/ai/ai_trace.dart';
import 'package:money_navigation/services/ai/cloud_speech.dart';
import 'package:money_navigation/services/ai/gemini_item.dart';
import 'package:money_navigation/rules/new_item.dart';
import 'package:money_navigation/services/clip_recorder.dart';

import 'haggle_controller_test.dart'
    show FakeSpeech, FakeTts, FakeResolver, FakePlaces, FakeVoice, settle;

/// Records nothing; returns [clip] at once, or waits until [stop] when
/// [hold] is true.
class FakeRecorder implements ClipRecorder {
  FakeRecorder({
    this.clip,
    this.hold = false,
    this.levels = const [0.5],
    this.outcomes = const [],
  });

  Uint8List? clip;

  /// Outcome per record call, the last repeated; default from [clip].
  final List<ClipOutcome> outcomes;
  ClipOutcome _outcome = ClipOutcome.failed;
  bool? micReadyDuringRecord;
  bool Function()? probeMicReady;

  @override
  ClipOutcome get lastOutcome => _outcome;
  final bool hold;
  final List<double> levels;
  int recordCalls = 0;
  int stopCalls = 0;
  int disposeCalls = 0;
  final seenLevels = <double>[];
  Completer<Uint8List?>? _pending;

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<Uint8List?> record({
    required void Function(double level) onLevel,
    void Function()? onSpeech,
    void Function()? onStarted,
  }) async {
    recordCalls++;
    onStarted?.call();
    micReadyDuringRecord = probeMicReady?.call();
    final i = recordCalls - 1;
    _outcome = outcomes.isEmpty
        ? (clip == null ? ClipOutcome.failed : ClipOutcome.speech)
        : outcomes[i < outcomes.length ? i : outcomes.length - 1];
    if (_outcome == ClipOutcome.silence) return null;
    for (final l in levels) {
      seenLevels.add(l);
      onLevel(l);
    }
    if (!hold) return clip;
    final p = _pending = Completer<Uint8List?>();
    return p.future;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    final p = _pending;
    _pending = null;
    if (p != null && !p.isCompleted) p.complete(clip);
  }

  @override
  Future<void> dispose() async => disposeCalls++;
}

class FakeCloudSpeech implements CloudSpeech {
  FakeCloudSpeech(this.answers);

  /// When set, recognize waits for this before answering.
  Completer<void>? gate;

  /// One answer per call, the last repeated; null means the cloud failed.
  final List<List<String>?> answers;
  final calls = <(Uint8List, int, List<String>)>[];
  static const trace = AiTrace(
    AiEngine.cloudSpeech,
    Duration(milliseconds: 1200),
  );

  @override
  Future<(List<String>, AiTrace)?> recognize(
    Uint8List audio, {
    String encoding = 'LINEAR16',
    int sampleRateHertz = 16000,
    List<String> phrases = const [],
  }) async {
    calls.add((audio, sampleRateHertz, phrases));
    await gate?.future;
    final a =
        answers[calls.length - 1 < answers.length
            ? calls.length - 1
            : answers.length - 1];
    return a == null ? null : (a, trace);
  }
}

class CountingTts extends FakeTts {
  int prepareCalls = 0;

  @override
  Future<bool> prepare() async {
    prepareCalls++;
    return super.prepare();
  }
}

class FakeGuesser implements GeminiItemResolver {
  FakeGuesser(this.answer);
  final ItemGuess? Function(List<MarketItem> items) answer;
  int calls = 0;

  @override
  Future<ItemGuess?> resolve(
    List<String> alternatives,
    List<MarketItem> items, {
    PriceUnit? unit,
  }) async {
    calls++;
    return answer(items);
  }
}

const guessTrace = AiTrace(AiEngine.gemini, Duration(milliseconds: 2600));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<SourcedItem> items;
  setUpAll(() async => items = await MarketPriceRepository().load());

  late FakeSpeech speech;
  late CountingTts tts;
  late FakeRecorder recorder;
  late FakeCloudSpeech cloud;
  final clip = Uint8List.fromList(List<int>.filled(3200, 7));

  HaggleController build({
    FakeRecorder? withRecorder,
    List<List<String>?> answers = const [
      ['มะม่วงกิโลละ 150'],
    ],
    bool cloudFirst = true,
    FakeGuesser? guesser,
  }) {
    speech = FakeSpeech();
    tts = CountingTts();
    recorder = withRecorder ?? FakeRecorder(clip: clip);
    cloud = FakeCloudSpeech(answers);
    return HaggleController(
      speech: speech,
      tts: tts,
      resolver: FakeResolver((_) => null),
      places: FakePlaces(),
      voice: FakeVoice(),
      recorder: recorder,
      cloudSpeech: cloud,
      cloudFirst: cloudFirst,
      itemGuesser: guesser ?? FakeGuesser((_) => null),
    );
  }

  void expectMango150(HaggleState s) {
    expect(s.phase, HagglePhase.done);
    expect(s.match?.item.key, 'mango');
    expect(s.heard?.amount, 150);
    expect(s.verdict?.verdict, PriceVerdict.high);
    expect(s.problem, isNull);
    expect(s.typed, isFalse);
  }

  test('cloud first: records once, sends 16 kHz clip with hints', () async {
    final c = build();
    await c.start();
    await settle();

    expect(recorder.recordCalls, 1);
    expect(recorder.seenLevels, [0.5]);
    expect(cloud.calls, hasLength(1));
    final (audio, rate, hints) = cloud.calls.single;
    expect(audio, same(clip));
    expect(rate, 16000);
    expect(rate, ClipRecorder.sampleRate);
    expect(hints, contains('มะม่วง'));
    for (final s in items) {
      expect(hints, containsAll(s.item.keywordsTh));
    }
    expect(hints, containsAll(pricePhrasesTh));
    expect(hints, containsAll(['กิโลละ', 'ลูกละ', 'บาท']));

    expectMango150(c.state);
    expect(c.state.words, 'มะม่วงกิโลละ 150');
    expect(c.heardTrace, same(FakeCloudSpeech.trace));
    expect(speech.listenCalls, 0);
    c.dispose();
  });

  test('picks the first transcript that names an item', () async {
    final names = [for (final s in items) s.item];
    // The unmatched transcript must really name no item, or this proves
    // nothing.
    expect(parseHeardPrice('อะไรกิโลละ 150', names)?.item, isNull);
    final c = build(
      answers: [
        ['อะไรกิโลละ 150', 'มะม่วงกิโลละ 150'],
      ],
    );
    await c.start();
    await settle();
    expectMango150(c.state);
    expect(c.state.words, 'มะม่วงกิโลละ 150');
    expect(speech.listenCalls, 0);
    c.dispose();
  });

  test('nothing recorded falls back to the phone, and stays there', () async {
    final c = build(withRecorder: FakeRecorder(clip: null));
    await c.start();
    await settle();
    expect(recorder.recordCalls, 1);
    expect(cloud.calls, isEmpty);
    expect(speech.listenCalls, 1);
    expect(c.state.phase, HagglePhase.listening);
    expect(c.heardTrace, isNull);

    speech.say('มะม่วงกิโลละ 150');
    expectMango150(c.state);

    await c.listen();
    await settle();
    expect(recorder.recordCalls, 1, reason: 'later listens use the phone');
    expect(speech.listenCalls, 2);
    c.dispose();
  });

  test('cloud offline falls back to the phone; no heard trace', () async {
    final c = build(answers: [null]);
    await c.start();
    await settle();
    expect(recorder.recordCalls, 1);
    expect(cloud.calls, hasLength(1));
    expect(speech.listenCalls, 1);
    expect(c.heardTrace, isNull);
    expect(c.state.phase, HagglePhase.listening);

    speech.say('มะม่วงกิโลละ 150');
    expectMango150(c.state);
    expect(c.heardTrace, isNull);

    await c.listen();
    await settle();
    expect(recorder.recordCalls, 1);
    expect(cloud.calls, hasLength(1));
    expect(speech.listenCalls, 2);
    c.dispose();
  });

  test('listenForReply through the cloud applies an accept', () async {
    final c = build(
      answers: [
        ['มะม่วงกิโลละ 150'],
        ['ตกลง'],
      ],
    );
    await c.start();
    await settle();
    expectMango150(c.state);

    await c.listenForReply();
    await settle();
    expect(recorder.recordCalls, 2);
    expect(cloud.calls, hasLength(2));
    expect(c.exchanges, hasLength(1));
    expect(c.exchanges.single.words, 'ตกลง');
    expect(c.exchanges.single.reply.kind, ReplyKind.accept);
    expect(c.exchanges.single.move.kind, MoveKind.accept);
    expect(c.hearingReply, isFalse);
    expect(c.state.phase, HagglePhase.done);
    expect(c.state.verdict?.counterOffer, 110);
    expect(speech.listenCalls, 0);
    c.dispose();
  });

  test('stopListening while recording stops the recorder only', () async {
    final c = build(withRecorder: FakeRecorder(clip: clip, hold: true));
    final started = c.start();
    await settle();
    expect(c.state.phase, HagglePhase.listening);
    expect(recorder.recordCalls, 1);

    expect(c.wordsAfterSentence, isTrue);
    expect(c.readingSentence, isFalse);
    cloud.gate = Completer<void>();

    await c.stopListening();
    await settle();
    expect(c.wordsAfterSentence, isFalse);
    expect(c.readingSentence, isTrue);
    cloud.gate!.complete();
    await started;
    await settle();
    expect(c.readingSentence, isFalse);
    expect(recorder.stopCalls, 1);
    expect(speech.listenCalls, 0);
    expect(speech.stopCalls, 0);
    // The clip so far still went to the cloud.
    expect(cloud.calls, hasLength(1));
    expectMango150(c.state);
    c.dispose();
  });

  test('submitManual while recording wins over the late clip', () async {
    final c = build(
      withRecorder: FakeRecorder(clip: clip, hold: true),
      answers: [
        ['มะม่วงกิโลละ 150'],
      ],
    );
    final started = c.start();
    await settle();
    expect(c.state.phase, HagglePhase.listening);

    final mango = items.firstWhere((s) => s.item.key == 'mango');
    await c.submitManual(mango, 60);
    await started;
    await settle();
    await settle();

    expect(recorder.stopCalls, 1);
    expect(speech.listenCalls, 0);
    final s = c.state;
    expect(s.phase, HagglePhase.done);
    expect(s.typed, isTrue);
    expect(s.heard?.amount, 60);
    expect(s.match?.item.key, 'mango');
    expect(s.verdict?.verdict, isNot(PriceVerdict.high));
    expect(c.heardTrace, isNull);
    c.dispose();
  });

  test('a running phone recognizer is cancelled before recording', () async {
    final c = build();
    await c.start();
    await settle();
    expect(speech.cancelCalls, 0);
    speech.listening = true;
    await c.listen();
    await settle();
    expect(speech.cancelCalls, 1);
    expect(recorder.recordCalls, 2);
    expect(speech.listenCalls, 0);
    expectMango150(c.state);
    c.dispose();
  });

  test('the voice is prepared again after a clip', () async {
    final c = build();
    await c.start();
    await settle();
    expect(tts.prepareCalls, 1, reason: 'prepare runs only at start');
    expect(tts.restoreCalls, 1, reason: 'speaker given back after the clip');

    await c.listen();
    await settle();
    expect(tts.prepareCalls, 1);
    expect(tts.restoreCalls, 2);
    c.dispose();
  });

  test('silence records again; the cloud still hears it', () async {
    final rec = FakeRecorder(
      clip: clip,
      outcomes: const [
        ClipOutcome.silence,
        ClipOutcome.silence,
        ClipOutcome.speech,
      ],
    );
    final c = build(withRecorder: rec);
    rec.probeMicReady = () => c.micReady;
    await c.start();
    await settle();

    expect(rec.recordCalls, 3);
    expect(rec.micReadyDuringRecord, isTrue);
    expect(c.micReady, isFalse);
    expectMango150(c.state);
    expect(speech.listenCalls, 0);
    c.dispose();
  });

  test('a failed recorder hands over to the phone', () async {
    final rec = FakeRecorder(outcomes: const [ClipOutcome.failed]);
    final c = build(withRecorder: rec);
    await c.start();
    await settle();

    expect(rec.recordCalls, 1);
    expect(speech.listenCalls, greaterThan(0));
    c.dispose();
  });

  test('an item outside the list is named and kept, with no verdict', () async {
    final c = build(
      answers: const [
        ['ลาเต้วานิลลาแก้วละ 120'],
      ],
      guesser: FakeGuesser(
        (_) => const ItemGuess(
          newItem: NewItem(
            nameTh: 'ลาเต้วานิลลา',
            nameEn: 'Vanilla latte',
            unit: PriceUnit.each,
            category: ItemCategory.drink,
          ),
          confidence: 0.95,
          trace: guessTrace,
        ),
      ),
    );
    await c.start();
    await settle();
    expect(c.newItem?.nameEn, 'Vanilla latte');
    expect(c.newItem?.key, 'new:ลาเต้วานิลลา');
    expect(c.itemGuessTrace, same(guessTrace));
    expect(c.state.heard?.amount, 120);
    expect(c.state.verdict, isNull);
    c.dispose();
  });

  test(
    'a known item from Gemini is only a suggestion until confirmed',
    () async {
      final c = build(
        answers: const [
          ['อะไรกิโลละ 150'],
        ],
        guesser: FakeGuesser(
          (items) => ItemGuess(
            known: items.firstWhere((i) => i.key == 'mango'),
            confidence: 0.92,
            trace: guessTrace,
          ),
        ),
      );
      await c.start();
      await settle();
      expect(c.suggestion?.item.key, 'mango');
      expect(c.state.verdict, isNull);
      c.acceptSuggestion(true);
      expectMango150(c.state);
      expect(c.suggestion, isNull);
      c.dispose();
    },
  );

  test('a typed item outside the list keeps the typed price', () async {
    final c = build();
    await c.start();
    await settle();
    c.useTypedItem('Sunscreen', 350);
    expect(c.newItem?.nameEn, 'Sunscreen');
    expect(c.state.heard?.amount, 350);
    expect(c.state.typed, isTrue);
    c.dispose();
  });

  test('cloudFirst false keeps the phone recognizer', () async {
    final c = build(cloudFirst: false);
    await c.start();
    await settle();
    expect(recorder.recordCalls, 0);
    expect(recorder.stopCalls, 0);
    expect(cloud.calls, isEmpty);
    expect(speech.listenCalls, 1);
    speech.say('มะม่วงกิโลละ 150');
    expectMango150(c.state);
    expect(c.heardTrace, isNull);
    await c.stopListening();
    expect(recorder.stopCalls, 0);
    c.dispose();
    expect(recorder.disposeCalls, 0, reason: 'an injected recorder is ours');
  });
}
