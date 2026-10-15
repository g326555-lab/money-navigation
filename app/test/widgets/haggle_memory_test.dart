import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/data/market_price_repository.dart';
import 'package:money_navigation/features/speak/haggle_controller.dart';
import 'package:money_navigation/features/speak/haggle_screen.dart';
import 'package:money_navigation/features/speak/show_seller_screen.dart';
import 'package:money_navigation/rules/demo_personas.dart';
import 'package:money_navigation/rules/haggle.dart';
import 'package:money_navigation/rules/trip_ledger.dart';

import 'haggle_controller_test.dart'
    show FakePlaces, FakeResolver, FakeSpeech, FakeTts, FakeVoice;
import 'harness.dart';

const pastHaggles = 'Your past haggles';

/// Amounts keep the number and currency together with a no-break space.
const sampleFooter =
    'You paid 90\u00A0THB at Or Tor Kor Market yesterday'
    ' · from 2 sample records';
const realFooter =
    'You paid 90\u00A0THB at Or Tor Kor Market yesterday'
    ' · from your 2 past records';

const wakelockChannel =
    'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle';

/// The visitor demo samples, read from the real demo file.
List<TripSave> visitorSamples(DateTime now) {
  final personas = parseDemoPersonas(
    File(demoPersonasAsset).readAsStringSync(),
  )!;
  return personas.byKey('visitorBangkok')!.samplesAt(now);
}

/// The traveler's own haggles (not samples) with the visitor's mango
/// figures: 140 -> 100 two days ago, 150 -> 90 at Or Tor Kor yesterday.
List<TripSave> ownMangoSaves(DateTime now) {
  DateTime at(int daysAgo, int h, int m) =>
      DateTime(now.year, now.month, now.day - daysAgo, h, m);
  TripSave mango(
    String id,
    DateTime t,
    double asked,
    double paid,
    String place,
  ) => TripSave(
    id: id,
    kind: SaveKind.haggle,
    keptThb: asked - paid,
    savedAt: t,
    itemKey: 'mango',
    askedThb: asked,
    paidThb: paid,
    placeName: place,
  );
  return [
    mango('own-1', at(2, 14, 10), 140, 100, 'Khao San Road'),
    mango('own-2', at(1, 10, 40), 150, 90, 'Or Tor Kor Market'),
  ];
}

void main() {
  late SourcedItem mango;

  setUpAll(() async {
    await warmMarketPrices();
    mango = (await MarketPriceRepository().load()).firstWhere(
      (s) => s.item.key == 'mango',
    );
  });
  setUp(resetPreferences);

  /// Pumps HaggleScreen with fakes and enters mango at 150 THB by hand:
  /// High, counter-offer 110.
  Future<HaggleController> pumpVerdict(
    WidgetTester tester,
    Stores stores,
  ) async {
    setLogicalSize(tester, const Size(430, 3000));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
          wakelockChannel,
          (_) async =>
              const StandardMessageCodec().encodeMessage(<Object?>[null]),
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(wakelockChannel, null),
    );
    final c = HaggleController(
      speech: FakeSpeech(),
      tts: FakeTts(),
      resolver: FakeResolver((_) => null),
      places: FakePlaces(),
      voice: FakeVoice(),
    );
    await tester.pumpWidget(wrap(stores, HaggleScreen(controller: c)));
    await pumpFrames(tester, frames: 5);
    expect(c.state.phase, HagglePhase.listening);

    await c.submitManual(mango, 150);
    await pumpFrames(tester);
    expect(c.state.verdict?.verdict, PriceVerdict.high);
    expect(c.state.verdict?.counterOffer, 110);
    return c;
  }

  Future<Stores> storesWith(List<TripSave> saves, {bool demo = false}) async {
    final stores = Stores();
    await stores.trip.load();
    await stores.settings.load();
    if (demo) {
      stores.trip.showDemo('visitorBangkok', saves);
    } else {
      for (final s in saves) {
        await stores.trip.add(s);
      }
    }
    return stores;
  }

  testWidgets('with no saves there is no memory line or past haggles row', (
    tester,
  ) async {
    final stores = await storesWith(const []);
    await pumpVerdict(tester, stores);

    expect(find.text('110 THB'), findsWidgets);
    expect(find.textContaining('You paid'), findsNothing);
    expect(find.text(pastHaggles), findsNothing);
    expect(find.textContaining('off the first price'), findsNothing);
    await drainTimers(tester);
  });

  testWidgets('visitor demo samples give the memory line, marked samples', (
    tester,
  ) async {
    final samples = visitorSamples(DateTime.now());
    expect(samples.every((s) => s.isSample), isTrue);
    final stores = await storesWith(samples, demo: true);
    await pumpVerdict(tester, stores);

    expect(find.text(sampleFooter), findsOneWidget);
    expect(find.text(pastHaggles), findsOneWidget);
    // Mango 140 -> 100 (28.6 %) and 150 -> 90 (40 %): median 34.3 %.
    expect(find.text('About 34 % off the first price'), findsOneWidget);
    expect(find.text('from 2 sample records'), findsOneWidget);
    expect(find.textContaining('past records'), findsNothing);
    await drainTimers(tester);
  });

  testWidgets('the traveler\'s own saves say "from your 2 past records"', (
    tester,
  ) async {
    final real = ownMangoSaves(DateTime.now());
    expect(real.every((s) => !s.isSample), isTrue);
    final stores = await storesWith(real);
    expect(stores.trip.showingDemo, isFalse);
    await pumpVerdict(tester, stores);

    expect(find.text(realFooter), findsOneWidget);
    expect(find.text(pastHaggles), findsOneWidget);
    expect(find.text('About 34 % off the first price'), findsOneWidget);
    expect(find.text('from your 2 past records'), findsOneWidget);
    expect(find.textContaining('sample'), findsNothing);
    await drainTimers(tester);
  });

  testWidgets('the counter card opens Show the seller with 110 บาท', (
    tester,
  ) async {
    final stores = await storesWith(const []);
    await pumpVerdict(tester, stores);

    final button = find.text('Show the seller');
    expect(button, findsOneWidget);
    expect(find.text('Could you do 110 baht?'), findsOneWidget);
    await tester.ensureVisible(button);
    await pumpFrames(tester, frames: 5);
    await tester.tap(button);
    await pumpFrames(tester);

    expect(find.byType(ShowSellerScreen), findsOneWidget);
    final screen = tester.widget<ShowSellerScreen>(
      find.byType(ShowSellerScreen),
    );
    expect(screen.amount, '110 บาท');
    expect(screen.meaning, 'Could you do 110 baht?');
    expect(
      find.descendant(
        of: find.byType(ShowSellerScreen),
        matching: find.text('110 บาท'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(ShowSellerScreen),
        matching: find.text(screen.sentence),
      ),
      findsOneWidget,
    );
    expect(screen.sentence, startsWith('ลดเหลือ 110 บาทได้ไหม'));
    expect(tester.takeException(), isNull);
    await drainTimers(tester);
  });
}
