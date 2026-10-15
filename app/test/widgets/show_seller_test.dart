import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/app/theme.dart';
import 'package:money_navigation/features/speak/haggle_controller.dart';
import 'package:money_navigation/features/speak/show_seller_screen.dart';
import 'package:money_navigation/l10n/app_localizations.dart';

import 'haggle_controller_test.dart'
    show FakePlaces, FakeResolver, FakeSpeech, FakeTts, FakeVoice;
import 'harness.dart';

const sentence = 'ลดเหลือ 110 บาทได้ไหมครับ';
const amount = '110 บาท';
const meaning = 'Could you do 110 baht?';

/// The pigeon channel wakelock_plus toggles the screen lock through.
const wakelockChannel =
    'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle';

class WakeCalls {
  int count = 0;
}

/// Answers the wakelock toggle like the platform would; counts the calls.
WakeCalls mockWakelock() {
  final calls = WakeCalls();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler(wakelockChannel, (message) async {
        calls.count++;
        return const StandardMessageCodec().encodeMessage(<Object?>[null]);
      });
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(wakelockChannel, null),
  );
  return calls;
}

/// A home with one button that pushes the screen, so closing can be seen.
Widget host(
  HaggleController haggle, {
  String? withMeaning = meaning,
  String? withAmount = amount,
  bool reduceMotion = false,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: buildAppTheme(),
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
    child: child!,
  ),
  home: Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ShowSellerScreen(
                haggle: haggle,
                sentence: sentence,
                amount: withAmount,
                meaning: withMeaning,
              ),
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  ),
);

Future<void> open(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await pumpFrames(tester, frames: 20);
}

RotationTransition wordsRotation(WidgetTester tester) =>
    tester.widget<RotationTransition>(
      find.descendant(
        of: find.byType(AnimatedRotation),
        matching: find.byType(RotationTransition),
      ),
    );

void main() {
  setUpAll(warmMarketPrices);

  late FakeVoice voice;
  late FakeTts tts;

  /// A controller with fakes, started so canSpeak reflects [ttsReady].
  Future<HaggleController> controller(
    WidgetTester tester, {
    bool ttsReady = true,
  }) async {
    voice = FakeVoice();
    tts = FakeTts(ready: ttsReady);
    final c = HaggleController(
      speech: FakeSpeech(),
      tts: tts,
      resolver: FakeResolver((_) => null),
      places: FakePlaces(),
      voice: voice,
    );
    await tester.runAsync(c.start);
    addTearDown(c.dispose);
    return c;
  }

  testWidgets('shows the amount, the Thai sentence and its meaning', (
    tester,
  ) async {
    mockWakelock();
    final c = await controller(tester);
    await tester.pumpWidget(host(c));
    await open(tester);

    expect(find.byType(ShowSellerScreen), findsOneWidget);
    expect(find.text(amount), findsOneWidget);
    expect(find.text(sentence), findsOneWidget);
    expect(find.text(meaning), findsOneWidget);
    expect(find.text('Tap the sentence to close'), findsOneWidget);
    expect(find.text('Turn to the seller'), findsOneWidget);
  });

  testWidgets('no meaning line when the meaning is null', (tester) async {
    mockWakelock();
    final c = await controller(tester);
    await tester.pumpWidget(host(c, withMeaning: null));
    await open(tester);

    expect(find.text(sentence), findsOneWidget);
    expect(find.text(amount), findsOneWidget);
    expect(find.text(meaning), findsNothing);
  });

  testWidgets('no amount when the move has no price', (tester) async {
    mockWakelock();
    final c = await controller(tester);
    await tester.pumpWidget(host(c, withAmount: null));
    await open(tester);

    expect(find.text(sentence), findsOneWidget);
    expect(find.text(amount), findsNothing);
  });

  testWidgets('tapping the sentence closes the screen', (tester) async {
    mockWakelock();
    final c = await controller(tester);
    await tester.pumpWidget(host(c));
    await open(tester);

    await tester.tap(find.text(sentence));
    await pumpFrames(tester, frames: 20);
    expect(find.byType(ShowSellerScreen), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('turning rotates the words but not the buttons', (tester) async {
    mockWakelock();
    final c = await controller(tester);
    await tester.pumpWidget(host(c));
    await open(tester);

    final rotation = tester.widget<AnimatedRotation>(
      find.byType(AnimatedRotation),
    );
    expect(rotation.turns, 0);
    expect(
      find.descendant(
        of: find.byType(AnimatedRotation),
        matching: find.text(sentence),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Turn to the seller'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // Mid-turn with motion on.
    final mid = wordsRotation(tester).turns.value;
    expect(mid, greaterThan(0));
    expect(mid, lessThan(0.5));
    await pumpFrames(tester, frames: 20);

    expect(find.text('Turn back to me'), findsOneWidget);
    expect(find.text('Turn to the seller'), findsNothing);
    expect(
      tester.widget<AnimatedRotation>(find.byType(AnimatedRotation)).turns,
      0.5,
    );
    expect(wordsRotation(tester).turns.value, 0.5);
    // The buttons keep facing the traveler.
    for (final label in ['Turn back to me', 'Say it in Thai']) {
      expect(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(AnimatedRotation),
        ),
        findsNothing,
        reason: label,
      );
    }
    // The screen did not close: the turn button is outside the words.
    expect(find.byType(ShowSellerScreen), findsOneWidget);

    await tester.tap(find.text('Turn back to me'));
    await pumpFrames(tester, frames: 20);
    expect(find.text('Turn to the seller'), findsOneWidget);
    expect(
      tester.widget<AnimatedRotation>(find.byType(AnimatedRotation)).turns,
      0,
    );
  });

  testWidgets('with reduce motion the words turn at once', (tester) async {
    mockWakelock();
    final c = await controller(tester);
    await tester.pumpWidget(host(c, reduceMotion: true));
    await open(tester);

    await tester.tap(find.text('Turn to the seller'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Turn back to me'), findsOneWidget);
    expect(wordsRotation(tester).turns.value, 0.5);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Say it speaks the sentence through the controller', (
    tester,
  ) async {
    mockWakelock();
    final c = await controller(tester);
    expect(c.state.canSpeak, isTrue);
    await tester.pumpWidget(host(c));
    await open(tester);

    await tester.tap(find.text('Say it in Thai'));
    await pumpFrames(tester, frames: 5);
    expect(voice.spoken, [sentence]);
    expect(tts.spoken, [sentence]);
  });

  testWidgets('no Say it button when the phone has no Thai voice', (
    tester,
  ) async {
    mockWakelock();
    final c = await controller(tester, ttsReady: false);
    expect(c.state.canSpeak, isFalse);
    await tester.pumpWidget(host(c));
    await open(tester);

    expect(find.text('Say it in Thai'), findsNothing);
    expect(find.text('Turn to the seller'), findsOneWidget);
    expect(voice.spoken, isEmpty);
  });

  testWidgets('a missing wakelock platform never escapes the screen', (
    tester,
  ) async {
    // No mock handler: the pigeon call fails like on a platform without
    // the plugin; the screen swallows it.
    final c = await controller(tester);
    await tester.pumpWidget(host(c));
    await open(tester);
    expect(tester.takeException(), isNull);
    expect(find.text(sentence), findsOneWidget);

    await tester.tap(find.text(sentence));
    await pumpFrames(tester, frames: 20);
    expect(tester.takeException(), isNull);
    expect(find.byType(ShowSellerScreen), findsNothing);
  });

  testWidgets('the screen asks to stay awake and lets go on close', (
    tester,
  ) async {
    final calls = mockWakelock();
    final c = await controller(tester);
    await tester.pumpWidget(host(c));
    await open(tester);
    expect(calls.count, 1);

    await tester.tap(find.text(sentence));
    await pumpFrames(tester, frames: 20);
    expect(calls.count, 2);
  });
}
