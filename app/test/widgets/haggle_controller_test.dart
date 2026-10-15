import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/data/market_price_repository.dart';
import 'package:money_navigation/features/speak/haggle_controller.dart';
import 'package:money_navigation/rules/haggle.dart';
import 'package:money_navigation/services/ai/ai_trace.dart';
import 'package:money_navigation/services/ai/item_matcher.dart';
import 'package:money_navigation/services/ai/item_resolver.dart';
import 'package:money_navigation/services/cloud_voice.dart';
import 'package:money_navigation/services/places_service.dart';
import 'package:money_navigation/services/speech_service.dart';
import 'package:money_navigation/services/tts_service.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

typedef OnWords = void Function(
  String words,
  bool isFinal,
  List<String> alternatives,
);

/// Stands in for speech_to_text; the test speaks through [say].
class FakeSpeech implements SpeechService {
  FakeSpeech({this.available = true, this.permission = true});

  final bool available;
  final bool permission;
  bool listening = false;
  int listenCalls = 0;
  int cancelCalls = 0;
  int stopCalls = 0;
  int startedCalls = 0;
  List<String> phrases = const [];
  OnWords? _onWords;
  void Function(String status)? onStatus;
  void Function(SpeechRecognitionError error)? onError;

  void say(String words, {bool isFinal = true, List<String> alts = const []}) =>
      _onWords!(words, isFinal, alts);

  @override
  Future<bool> prepare({
    required void Function(String status) onStatus,
    required void Function(SpeechRecognitionError error) onError,
  }) async {
    this.onStatus = onStatus;
    this.onError = onError;
    return available;
  }

  @override
  bool get isListening => listening;

  @override
  Future<bool> get hasPermission async => permission;

  @override
  Future<void> listen({
    required OnWords onWords,
    required void Function(double level) onLevel,
    required List<String> phrases,
  }) async {
    listenCalls++;
    listening = true;
    this.phrases = phrases;
    _onWords = onWords;
  }

  @override
  void speechStarted() => startedCalls++;

  @override
  Future<void> stop() async {
    stopCalls++;
    listening = false;
  }

  @override
  Future<void> cancel() async {
    cancelCalls++;
    listening = false;
  }
}

class FakeTts implements TtsService {
  FakeTts({this.ready = true});
  final bool ready;
  final spoken = <String>[];
  int stopCalls = 0;

  @override
  Future<bool> prepare() async => ready;

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async => stopCalls++;
}

class FakeResolver implements ItemResolver {
  FakeResolver(this.answer);
  final ItemMatch? Function(List<SourcedItem> items) answer;
  final calls = <(List<String>, PriceUnit?)>[];

  @override
  Future<ItemMatch?> resolve(
    List<String> alternatives,
    List<SourcedItem> items, {
    PriceUnit? unit,
  }) async {
    calls.add((alternatives, unit));
    return answer(items);
  }
}

class FakePlaces implements PlacesService {
  FakePlaces([this.evidence]);
  final PlacesEvidence? evidence;
  int calls = 0;

  @override
  Future<PlacesEvidence?> nearbyMarket() async {
    calls++;
    return evidence;
  }
}

class FakeVoice implements CloudVoice {
  FakeVoice([this.trace]);
  final AiTrace? trace;
  final spoken = <String>[];
  bool disposed = false;

  @override
  Future<AiTrace?> speak(String text) async {
    spoken.add(text);
    return trace;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async => disposed = true;
}

/// Lets fire-and-forget futures (resolver, places) complete.
Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<SourcedItem> items;
  SourcedItem item(String key) => items.firstWhere((s) => s.item.key == key);

  setUpAll(() async => items = await MarketPriceRepository().load());

  late FakeSpeech speech;
  late FakeTts tts;
  late FakeResolver resolver;
  late FakePlaces places;
  late FakeVoice voice;

  HaggleController build({
    FakeSpeech? withSpeech,
    FakeTts? withTts,
    FakeResolver? withResolver,
    FakePlaces? withPlaces,
    FakeVoice? withVoice,
  }) {
    speech = withSpeech ?? FakeSpeech();
    tts = withTts ?? FakeTts();
    resolver = withResolver ?? FakeResolver((_) => null);
    places = withPlaces ?? FakePlaces();
    voice = withVoice ?? FakeVoice();
    return HaggleController(
      speech: speech,
      tts: tts,
      resolver: resolver,
      places: places,
      voice: voice,
    );
  }

  void expectDemoVerdict(HaggleState s) {
    expect(s.phase, HagglePhase.done);
    expect(s.match?.item.key, 'mango');
    expect(s.heard?.amount, 150);
    expect(s.heard?.unit, PriceUnit.perKg);
    expect(s.verdict?.verdict, PriceVerdict.high);
    expect(s.verdict?.overBy, 40);
    expect(s.verdict?.counterOffer, 110);
    expect(s.problem, isNull);
  }

  group('start', () {
    test(
      'listens with item names and price words as recognizer hints',
      () async {
        final c = build();
        await c.start();
        expect(c.state.phase, HagglePhase.listening);
        expect(c.state.canSpeak, isTrue);
        expect(speech.listenCalls, 1);
        expect(speech.phrases, containsAll(['มะม่วง', 'กิโลละ', 'ร้อย']));
        expect(c.items, hasLength(items.length));
        c.dispose();
      },
    );

    test('no Thai recognizer gives unavailable', () async {
      final c = build(withSpeech: FakeSpeech(available: false));
      await c.start();
      expect(c.state.phase, HagglePhase.unavailable);
      expect(speech.listenCalls, 0);
      c.dispose();
    });

    test('refused permission gives denied', () async {
      final c = build(withSpeech: FakeSpeech(permission: false));
      await c.start();
      expect(c.state.phase, HagglePhase.denied);
      expect(speech.listenCalls, 0);
      c.dispose();
    });

    test('a permission error while listening gives denied', () async {
      final c = build();
      await c.start();
      speech.onError!(SpeechRecognitionError('error_permission', true));
      expect(c.state.phase, HagglePhase.denied);
      c.dispose();
    });

    test('nearby market evidence arrives on its own', () async {
      final evidence = PlacesEvidence(
        place: const NearbyPlace(
          name: 'Or Tor Kor Market',
          rating: 4.5,
          ratingCount: 12000,
        ),
        trace: const AiTrace(AiEngine.googleMaps, Duration(milliseconds: 300)),
      );
      final c = build(withPlaces: FakePlaces(evidence));
      await c.start();
      await settle();
      expect(places.calls, 1);
      expect(c.places, same(evidence));
      c.dispose();
    });
  });

  group('heard speech (scene 2)', () {
    for (final sentence in [
      'มะม่วงกิโลละ 150',
      'มะม่วงกิโลละร้อยห้าสิบ',
      'มะม่วงกิโลละร้อยห้า',
    ]) {
      test('"$sentence" is High, 40 over, counter-offer 110', () async {
        final c = build();
        await c.start();
        speech.say(sentence);
        expectDemoVerdict(c.state);
        expect(c.state.words, sentence);
        expect(c.state.typed, isFalse);
        expect(speech.startedCalls, 1);
        expect(resolver.calls, isEmpty, reason: 'item was heard directly');
        c.dispose();
      });
    }

    test('a partial price settles into the verdict after a pause', () async {
      final c = build();
      await c.start();
      speech.say('มะม่วงกิโลละ 150', isFinal: false);
      expect(c.state.phase, HagglePhase.listening);
      expect(c.state.verdict?.verdict, PriceVerdict.high);
      await Future<void>.delayed(
        speechSettleAfterPrice + const Duration(milliseconds: 50),
      );
      expect(speech.stopCalls, 1);
      expectDemoVerdict(c.state);
      c.dispose();
    });

    test('the previous sentence coming back late is ignored', () async {
      final c = build();
      await c.start();
      speech.say('มะม่วงกิโลละ 150');
      await c.listen();
      speech.say('มะม่วงกิโลละ 150', isFinal: false);
      expect(c.state.phase, HagglePhase.listening);
      expect(c.state.words, isEmpty);
      c.dispose();
    });

    test('words without a price report noPrice', () async {
      final c = build();
      await c.start();
      speech.say('สวัสดีครับ');
      expect(c.state.phase, HagglePhase.done);
      expect(c.state.problem, HeardProblem.noPrice);
      expect(c.state.verdict, isNull);
      c.dispose();
    });
  });

  group('on-device AI names a misheard item', () {
    const misheard = 'มะมวงกิโลละ 150';

    test('the resolver gets the alternatives and the heard unit', () async {
      final c = build(
        withResolver: FakeResolver(
          (items) => ItemMatch(
            item: items.firstWhere((s) => s.item.key == 'mango').item,
            confidence: 0.9,
            reason: MatchReason.values.first,
          ),
        ),
      );
      await c.start();
      speech.say(misheard, alts: const [misheard, 'มะม่วงกิโล 150']);
      // Before the AI answers, the screen asks which item it was.
      expect(c.state.problem, HeardProblem.unknownItem);
      await settle();

      expect(resolver.calls, isNotEmpty);
      expect(resolver.calls.first.$1, [misheard, 'มะม่วงกิโล 150']);
      expect(resolver.calls.first.$2, PriceUnit.perKg);
      expect(c.aiMatch?.item.key, 'mango');
      expect(c.aiMatchWords, misheard);
      expect(c.aiMatchTrace?.engine, AiEngine.onDevice);
      expectDemoVerdict(c.state);
      c.dispose();
    });

    test(
      'when the AI is unsure, one tap on an item gives the verdict',
      () async {
        final c = build();
        await c.start();
        speech.say(misheard);
        await settle();
        expect(c.state.problem, HeardProblem.unknownItem);
        expect(c.aiMatch, isNull);

        c.chooseItem(item('mango'));
        expectDemoVerdict(c.state);
        c.dispose();
      },
    );

    test(
      'choosing an item sold in another unit reports unitMismatch',
      () async {
        final c = build();
        await c.start();
        speech.say(misheard);
        await settle();
        c.chooseItem(item('coconut'));
        expect(c.state.problem, HeardProblem.unitMismatch);
        expect(c.state.verdict, isNull);
        c.dispose();
      },
    );
  });

  group('typed price (submitManual)', () {
    test('mango at 150 is High with counter-offer 110, marked typed', () async {
      final c = build();
      await c.start();
      expect(speech.isListening, isTrue);
      await c.submitManual(item('mango'), 150);
      expect(speech.cancelCalls, 1, reason: 'stops the open listen');
      expectDemoVerdict(c.state);
      expect(c.state.typed, isTrue);
      c.dispose();
    });

    test('works without ever starting speech', () async {
      final c = build();
      await c.submitManual(item('mango'), 100);
      expect(c.state.phase, HagglePhase.done);
      expect(c.state.verdict?.verdict, PriceVerdict.fair);
      expect(c.state.verdict?.counterOffer, isNull);
      c.dispose();
    });
  });

  group('speaking the counter-offer', () {
    const sentence = 'ลดเหลือ 110 บาทได้ไหมครับ';

    test('the cloud voice speaks first and its trace is kept', () async {
      const trace = AiTrace(AiEngine.cloudTts, Duration(milliseconds: 420));
      final c = build(withVoice: FakeVoice(trace));
      await c.start();
      await c.speakCounter(sentence);
      expect(voice.spoken, [sentence]);
      expect(tts.spoken, isEmpty);
      expect(c.voiceTrace, same(trace));
      expect(c.state.speaking, isFalse);
      c.dispose();
    });

    test(
      'the phone voice speaks when the cloud voice is not available',
      () async {
        final c = build();
        await c.start();
        await c.speakCounter(sentence);
        expect(voice.spoken, [sentence]);
        expect(tts.spoken, [sentence]);
        expect(c.voiceTrace, isNull);
        c.dispose();
      },
    );

    test('nothing is spoken when the phone has no Thai voice', () async {
      final c = build(withTts: FakeTts(ready: false));
      await c.start();
      await c.speakCounter(sentence);
      expect(voice.spoken, isEmpty);
      expect(tts.spoken, isEmpty);
      c.dispose();
    });
  });

  test('dispose releases speech, tts and the cloud voice', () async {
    final c = build();
    await c.start();
    c.dispose();
    expect(speech.cancelCalls, 1);
    expect(tts.stopCalls, greaterThanOrEqualTo(1));
    expect(voice.disposed, isTrue);
  });
}
