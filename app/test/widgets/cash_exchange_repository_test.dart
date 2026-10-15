import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/data/cash_exchange_repository.dart';
import 'package:money_navigation/services/ai/cloud_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Answers `exchange-rates` like the deployed function, or fails like an
/// offline phone or an undeployed function.
class FakeFunctions extends CloudFunctions {
  FakeFunctions(this.answer);

  Map<String, dynamic>? Function() answer;
  int calls = 0;

  @override
  Future<Map<String, dynamic>> call(
    String name,
    Map<String, dynamic> body, {
    required Duration timeout,
  }) async {
    calls++;
    final value = answer();
    if (value == null) throw const CloudFunctionError('offline');
    return value;
  }
}

void main() {
  final refreshed = DateTime.utc(2026, 10, 16, 4);
  late DateTime clock;

  Map<String, dynamic> serverAnswer() => {
    'refreshedAt': refreshed.toIso8601String(),
    'stale': false,
    'data': {
      'generatedAt': refreshed.toIso8601String(),
      'stores': [],
      'rates': {},
      'sources': {},
    },
  };

  CashExchangeRepository repository(FakeFunctions functions) =>
      CashExchangeRepository(
        preferences: SharedPreferencesAsync(),
        functions: functions,
        clock: () => clock,
      );

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    clock = refreshed.add(const Duration(minutes: 5));
  });

  test('nothing cached and offline gives null, not an error', () async {
    final functions = FakeFunctions(() => null);
    expect(await repository(functions).load(), isNull);
    expect(functions.calls, 1);
  });

  test('a fresh answer is saved and reused offline', () async {
    final online = FakeFunctions(serverAnswer);
    final first = await repository(online).load();
    expect(first!['stale'], isFalse);

    // A new screen, same phone, no network.
    final offline = FakeFunctions(() => null);
    final reused = await repository(offline).load(force: true);
    expect(offline.calls, 1);
    expect(reused!['refreshedAt'], refreshed.toIso8601String());
    expect(reused['stale'], isFalse);
  });

  test('an offline copy past the snapshot limit is marked stale', () async {
    await repository(FakeFunctions(serverAnswer)).load();
    clock = refreshed.add(const Duration(minutes: 31));
    final reused = await repository(FakeFunctions(() => null)).load();
    expect(reused!['stale'], isTrue);
  });

  test(
    'a copy refreshed under a minute ago is reused without a call',
    () async {
      clock = refreshed.add(const Duration(seconds: 30));
      final functions = FakeFunctions(serverAnswer);
      final repo = repository(functions);
      await repo.load();
      await repo.load();
      expect(functions.calls, 1);
      await repo.load(force: true);
      expect(functions.calls, 2);
    },
  );

  test('a server time far in the future is stale', () async {
    clock = refreshed.subtract(const Duration(minutes: 10));
    final answer = await repository(FakeFunctions(serverAnswer)).load();
    expect(answer!['stale'], isTrue);
  });

  test('the server stale flag is kept even when times look fresh', () async {
    final answer = await repository(
      FakeFunctions(() => {...serverAnswer(), 'stale': true}),
    ).load();
    expect(answer!['stale'], isTrue);
  });
}
