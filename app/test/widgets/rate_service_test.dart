import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:money_navigation/services/rate_service.dart';

import 'harness.dart';

void main() {
  setUp(resetPreferences);

  // testWidgets runs in fake async, so the retry timer is driven by pump.
  testWidgets('a failed refresh retries after the first retry delay', (
    tester,
  ) async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      if (calls == 1) throw http.ClientException('offline', request.url);
      return http.Response(frankfurterKrwBody, 200);
    });
    final rates = RateService(client: client);

    await rates.ensure('KRW');
    expect(calls, 1);
    expect(rates.quoteFor('KRW'), isNull);
    expect(rates.unavailable('KRW'), isTrue);

    final first = RateService.retryDelays.first;
    await tester.pump(first - const Duration(milliseconds: 1));
    expect(calls, 1, reason: 'no retry before the first delay');

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(calls, 2);
    expect(rates.quoteFor('KRW')?.rate, 39.81);
    expect(rates.quoteFor('KRW')?.date, '2026-10-14');
    expect(rates.unavailable('KRW'), isFalse);
    expect(rates.refreshFailed('KRW'), isFalse);

    // Success ends the retries.
    await tester.pump(const Duration(minutes: 3));
    expect(calls, 2);
  });

  testWidgets('retries stop after the last scheduled delay', (tester) async {
    var calls = 0;
    final rates = RateService(
      client: MockClient((request) async {
        calls++;
        return http.Response('down', 503);
      }),
    );

    await rates.ensure('KRW');
    for (final delay in RateService.retryDelays) {
      await tester.pump(delay);
      await tester.pump();
    }
    expect(calls, 1 + RateService.retryDelays.length);
    await tester.pump(const Duration(minutes: 10));
    expect(calls, 1 + RateService.retryDelays.length);
    expect(rates.unavailable('KRW'), isTrue);
  });

  testWidgets(
    'a fresh cached rate is reused on the next launch without a request',
    (tester) async {
      final online = RateService(client: frankfurterClient());
      await online.ensure('KRW');
      expect(online.quoteFor('KRW')?.rate, 39.81);

      // Same device preferences, a new launch, no network. The cached quote
      // was fetched just now, so it is fresh and no refresh is attempted.
      var calls = 0;
      final offline = RateService(
        client: frankfurterClient(fail: true, onCall: () => calls++),
      );
      await offline.ensure('KRW');
      expect(offline.quoteFor('KRW')?.rate, 39.81);
      expect(offline.unavailable('KRW'), isFalse);
      expect(calls, 0);
    },
  );

  test('THB to THB needs no rate', () async {
    var calls = 0;
    final rates = RateService(client: frankfurterClient(onCall: () => calls++));
    await rates.ensure('THB');
    expect(calls, 0);
    expect(rates.quoteFor('THB'), isNull);
  });
}
