import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/services/auth/account_models.dart';

final onboarded = DateTime.utc(2026, 10, 15, 9, 30);

Map<String, Object?> fullRow() => {
  'id': 'user-1',
  'display_name': 'Mia',
  'traveler_type': 'visitor_in_thailand',
  'home_currency': 'USD',
  'card_currency': 'USD',
  'language': 'en',
  'onboarded_at': '2026-10-15T09:30:00+00:00',
};

void main() {
  group('TravelerType and AppLanguage db values', () {
    test('dbValue strings match the database', () {
      expect(TravelerType.visitorInThailand.dbValue, 'visitor_in_thailand');
      expect(TravelerType.thaiAbroad.dbValue, 'thai_abroad');
      expect(AppLanguage.en.dbValue, 'en');
      expect(AppLanguage.th.dbValue, 'th');
    });

    test('fromDb round trips every value', () {
      for (final t in TravelerType.values) {
        expect(TravelerType.fromDb(t.dbValue), t);
      }
      for (final l in AppLanguage.values) {
        expect(AppLanguage.fromDb(l.dbValue), l);
      }
    });

    test('fromDb returns null for null, unknown or non-string', () {
      expect(TravelerType.fromDb(null), isNull);
      expect(TravelerType.fromDb('resident'), isNull);
      expect(TravelerType.fromDb(1), isNull);
      expect(AppLanguage.fromDb(null), isNull);
      expect(AppLanguage.fromDb('fr'), isNull);
      expect(AppLanguage.fromDb(0), isNull);
    });
  });

  group('Profile.fromRow', () {
    test('reads a complete row', () {
      final p = Profile.fromRow(fullRow())!;
      expect(p.id, 'user-1');
      expect(p.displayName, 'Mia');
      expect(p.travelerType, TravelerType.visitorInThailand);
      expect(p.homeCurrency, 'USD');
      expect(p.cardCurrency, 'USD');
      expect(p.language, AppLanguage.en);
      expect(p.onboardedAt!.isAtSameMomentAs(onboarded), isTrue);
      expect(p.isComplete, isTrue);
    });

    test('a freshly created row (only id) is incomplete', () {
      final p = Profile.fromRow({'id': 'user-1'})!;
      expect(p.displayName, isNull);
      expect(p.travelerType, isNull);
      expect(p.homeCurrency, isNull);
      expect(p.cardCurrency, isNull);
      expect(p.language, isNull);
      expect(p.onboardedAt, isNull);
      expect(p.isComplete, isFalse);
    });

    test('null, non-map, missing or empty id give null', () {
      expect(Profile.fromRow(null), isNull);
      expect(Profile.fromRow('user-1'), isNull);
      expect(Profile.fromRow([fullRow()]), isNull);
      expect(Profile.fromRow(fullRow()..remove('id')), isNull);
      expect(Profile.fromRow(fullRow()..['id'] = ''), isNull);
      expect(Profile.fromRow(fullRow()..['id'] = 42), isNull);
    });

    test('unknown enum values become null instead of throwing', () {
      final p = Profile.fromRow(
        fullRow()
          ..['traveler_type'] = 'astronaut'
          ..['language'] = 'jp',
      )!;
      expect(p.travelerType, isNull);
      expect(p.language, isNull);
      expect(p.isComplete, isFalse);
    });

    test('bad currencies become null', () {
      for (final bad in ['usd', 'US', 'USDT', 'U5D', '', 840]) {
        final p = Profile.fromRow(fullRow()..['home_currency'] = bad)!;
        expect(p.homeCurrency, isNull, reason: 'home $bad');
        expect(p.isComplete, isFalse);
      }
      final p = Profile.fromRow(fullRow()..['card_currency'] = 'eur')!;
      expect(p.cardCurrency, isNull);
    });

    test('unparseable onboarded_at becomes null', () {
      final p = Profile.fromRow(fullRow()..['onboarded_at'] = 'yesterday')!;
      expect(p.onboardedAt, isNull);
      expect(p.isComplete, isFalse);
      final q = Profile.fromRow(fullRow()..['onboarded_at'] = 12345)!;
      expect(q.onboardedAt, isNull);
    });

    test('display name is optional for completeness', () {
      final p = Profile.fromRow(fullRow()..['display_name'] = null)!;
      expect(p.displayName, isNull);
      expect(p.isComplete, isTrue);
    });
  });

  group('Profile.isComplete needs every setup field', () {
    for (final key in [
      'traveler_type',
      'home_currency',
      'card_currency',
      'language',
      'onboarded_at',
    ]) {
      test('missing $key is incomplete', () {
        expect(Profile.fromRow(fullRow()..remove(key))!.isComplete, isFalse);
      });
    }
  });

  group('Profile.toSetupRow', () {
    test('writes setup columns with UTC ISO time and no id', () {
      final row = Profile.fromRow(fullRow())!.toSetupRow();
      expect(row, {
        'display_name': 'Mia',
        'traveler_type': 'visitor_in_thailand',
        'home_currency': 'USD',
        'card_currency': 'USD',
        'language': 'en',
        'onboarded_at': '2026-10-15T09:30:00.000Z',
      });
      expect(row.containsKey('id'), isFalse);
    });

    test('omits display_name when null', () {
      final row = Profile.fromRow(fullRow()..['display_name'] = null)!
          .toSetupRow();
      expect(row.containsKey('display_name'), isFalse);
      expect(row['traveler_type'], 'visitor_in_thailand');
    });

    test('converts a local onboarded time to UTC', () {
      final local = DateTime(2026, 10, 15, 16, 30);
      final row = Profile.fromRow(fullRow())!
          .copyWith(onboardedAt: local)
          .toSetupRow();
      expect(row['onboarded_at'], local.toUtc().toIso8601String());
      expect((row['onboarded_at'] as String).endsWith('Z'), isTrue);
    });

    test('thai abroad profile writes thai values', () {
      final row = Profile.fromRow(
        fullRow()
          ..['traveler_type'] = 'thai_abroad'
          ..['home_currency'] = 'THB'
          ..['card_currency'] = 'THB'
          ..['language'] = 'th',
      )!.toSetupRow();
      expect(row['traveler_type'], 'thai_abroad');
      expect(row['home_currency'], 'THB');
      expect(row['language'], 'th');
    });
  });

  group('Profile.copyWith', () {
    test('replaces only the given fields', () {
      final base = Profile.fromRow({'id': 'user-1'})!;
      final next = base.copyWith(
        travelerType: TravelerType.thaiAbroad,
        homeCurrency: 'THB',
      );
      expect(next.id, 'user-1');
      expect(next.travelerType, TravelerType.thaiAbroad);
      expect(next.homeCurrency, 'THB');
      expect(next.cardCurrency, isNull);
      expect(base.travelerType, isNull, reason: 'original is unchanged');
    });

    test('filling every setup field makes it complete', () {
      final p = Profile.fromRow({'id': 'user-1'})!.copyWith(
        travelerType: TravelerType.visitorInThailand,
        homeCurrency: 'JPY',
        cardCurrency: 'JPY',
        language: AppLanguage.en,
        onboardedAt: onboarded,
      );
      expect(p.isComplete, isTrue);
    });
  });

  group('defaultsFor', () {
    test('visitor uses the device currency for home and card, English', () {
      final d = defaultsFor(
        TravelerType.visitorInThailand,
        deviceCurrency: 'JPY',
      );
      expect(d.travelerType, TravelerType.visitorInThailand);
      expect(d.homeCurrency, 'JPY');
      expect(d.cardCurrency, 'JPY');
      expect(d.language, AppLanguage.en);
      expect(d.isValid, isTrue);
    });

    test('visitor on a THB device falls back to USD', () {
      final d = defaultsFor(
        TravelerType.visitorInThailand,
        deviceCurrency: 'THB',
      );
      expect(d.homeCurrency, 'USD');
      expect(d.cardCurrency, 'USD');
      expect(d.isValid, isTrue);
    });

    test('thai abroad is THB, THB, Thai regardless of device', () {
      for (final device in ['USD', 'THB', 'EUR']) {
        final d = defaultsFor(TravelerType.thaiAbroad, deviceCurrency: device);
        expect(d.travelerType, TravelerType.thaiAbroad);
        expect(d.homeCurrency, 'THB');
        expect(d.cardCurrency, 'THB');
        expect(d.language, AppLanguage.th);
        expect(d.isValid, isTrue);
      }
    });

    test('a garbled device currency never yields an invalid draft', () {
      for (final device in ['', 'usd', 'US', 'EURO']) {
        final d = defaultsFor(
          TravelerType.visitorInThailand,
          deviceCurrency: device,
        );
        expect(d.isValid, isTrue, reason: 'device "$device"');
      }
    });
  });

  group('ProfileDraft.isValid', () {
    ProfileDraft draft(String home, String card) => ProfileDraft(
      travelerType: TravelerType.visitorInThailand,
      homeCurrency: home,
      cardCurrency: card,
      language: AppLanguage.en,
    );

    test('true only when both currencies are three capital letters', () {
      expect(draft('USD', 'THB').isValid, isTrue);
      expect(draft('usd', 'THB').isValid, isFalse);
      expect(draft('USD', 'TH').isValid, isFalse);
      expect(draft('', 'THB').isValid, isFalse);
      expect(draft('USD', 'THBX').isValid, isFalse);
      expect(draft('U5D', 'THB').isValid, isFalse);
    });
  });
}
