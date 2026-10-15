import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/pay_facts.dart';
import 'package:money_navigation/rules/pay_route.dart';
import 'package:money_navigation/rules/personal_context.dart';

/// Fixed demo rate: 1 THB = 4.6935 JPY.
const double jpyToThb = 1 / 4.6935;

final SourcedFee thAtmFee = SourcedFee(
  value: 220,
  currency: 'THB',
  isPercent: false,
  source: 'Bangkok Bank fee schedule',
  checked: '2026-10-15',
);

final CountryPayFacts thFacts = CountryPayFacts(
  country: 'TH',
  currency: 'THB',
  foreignCardAtmFee: thAtmFee,
  atmOffersConversion: true,
);

final CountryPayFacts jpFacts = CountryPayFacts(
  country: 'JP',
  currency: 'JPY',
  foreignCardAtmFee: SourcedFee(
    value: 110,
    currency: 'JPY',
    isPercent: false,
    source: 'Seven Bank fee schedule',
    checked: '2026-10-14',
  ),
  atmOffersConversion: false,
);

const TravelerProfile card25NoFee = TravelerProfile(
  cardFeePercent: 2.5,
  atmFeePolicy: AtmFeePolicy.noFee,
);

PayOption opt(PayRoute r, PayMethod m) =>
    r.options.firstWhere((o) => o.method == m);

PayRoute th1000({
  double? withdrawalThb,
  TravelerProfile profile = card25NoFee,
  PlacePayment place = PlacePayment.unknown,
  CountryPayFacts? facts,
  bool noFacts = false,
  double? homeToThb,
  double? qrFeePercent,
  double amountLocal = 1000,
}) => payRoute(
  amountLocal: amountLocal,
  localToThb: 1,
  place: place,
  profile: profile,
  facts: noFacts ? null : (facts ?? thFacts),
  withdrawalThb: withdrawalThb,
  homeToThb: homeToThb,
  qrFeePercent: qrFeePercent,
);

void main() {
  group('PlacePayment', () {
    test('unknown has no evidence', () {
      expect(PlacePayment.unknown.known, isFalse);
      expect(PlacePayment.unknown.cashOnly, isNull);
      expect(PlacePayment.unknown.cards, isNull);
      expect(PlacePayment.unknown.nfc, isNull);
    });
    test('any field set is evidence', () {
      expect(const PlacePayment(cashOnly: false).known, isTrue);
      expect(const PlacePayment(cards: true).known, isTrue);
      expect(const PlacePayment(nfc: false).known, isTrue);
    });
  });

  group('TH 1000 THB, card 2.5 %, ATM 220 THB, noFee, withdrawal 2000', () {
    late PayRoute r;
    setUp(() => r = th1000(withdrawalThb: 2000));

    test('amountThb is 1000', () => expect(r.amountThb, 1000));
    test('options are card, cash, qr in this order', () {
      expect(
        [for (final o in r.options) o.method],
        [PayMethod.card, PayMethod.cash, PayMethod.qr],
      );
    });
    test('card adds 25.00', () {
      expect(opt(r, PayMethod.card).extraThb, 25.00);
      expect(opt(r, PayMethod.card).basis, ['cardFeePercent']);
    });
    test('cash adds 110.00 (220 x 1000 / 2000)', () {
      expect(opt(r, PayMethod.cash).extraThb, 110.00);
      expect(opt(r, PayMethod.cash).accepted, Acceptance.yes);
      expect(
        opt(r, PayMethod.cash).basis,
        containsAll(['foreignCardAtmFee', 'withdrawal']),
      );
    });
    test('best is card', () {
      expect(r.best, PayMethod.card);
      expect(r.sameCost, isFalse);
      expect(r.forcedByPlace, isFalse);
    });
    test('break-even withdrawal 8800.00 (220 / 0.025)', () {
      expect(r.breakEvenWithdrawalThb, 8800.00);
    });
    test('unknown place: card acceptance unknown, still comparable', () {
      expect(opt(r, PayMethod.card).accepted, Acceptance.unknown);
    });
    test('QR without a sourced fee is not compared', () {
      expect(opt(r, PayMethod.qr).extraThb, isNull);
      expect(opt(r, PayMethod.qr).accepted, Acceptance.unknown);
    });
  });

  group('withdrawal size moves the verdict', () {
    test('withdrawal 10000: cash 22.00 beats card 25.00', () {
      final r = th1000(withdrawalThb: 10000);
      expect(opt(r, PayMethod.cash).extraThb, 22.00);
      expect(opt(r, PayMethod.card).extraThb, 25.00);
      expect(r.best, PayMethod.cash);
      expect(r.sameCost, isFalse);
    });

    test('withdrawal 8800: 25.00 vs 25.00 is the same cost, no best', () {
      final r = th1000(withdrawalThb: 8800);
      expect(opt(r, PayMethod.cash).extraThb, 25.00);
      expect(opt(r, PayMethod.card).extraThb, 25.00);
      expect(r.best, isNull);
      expect(r.sameCost, isTrue);
    });

    test(
      'purchase above the withdrawal uses the purchase as the withdrawal',
      () {
        // 3000 THB with a planned 2000 withdrawal: one withdrawal of 3000,
        // fee 220 on 3000 -> the whole fee.
        final r = th1000(amountLocal: 3000, withdrawalThb: 2000);
        expect(opt(r, PayMethod.cash).extraThb, 220.00);
        expect(opt(r, PayMethod.card).extraThb, 75.00);
        expect(r.best, PayMethod.card);
      },
    );
  });

  group('place evidence', () {
    test('cash-only place forces cash', () {
      final r = th1000(
        withdrawalThb: 2000,
        place: const PlacePayment(cashOnly: true),
      );
      expect(r.best, PayMethod.cash);
      expect(r.forcedByPlace, isTrue);
      expect(r.sameCost, isFalse);
      expect(opt(r, PayMethod.card).accepted, Acceptance.no);
      expect(opt(r, PayMethod.cash).accepted, Acceptance.yes);
    });

    test('cash-only place forces cash even when cash cost is unknown', () {
      final r = th1000(place: const PlacePayment(cashOnly: true));
      expect(opt(r, PayMethod.cash).extraThb, isNull);
      expect(r.best, PayMethod.cash);
      expect(r.forcedByPlace, isTrue);
    });

    test('place takes cards: card accepted yes', () {
      final r = th1000(
        withdrawalThb: 2000,
        place: const PlacePayment(cards: true),
      );
      expect(opt(r, PayMethod.card).accepted, Acceptance.yes);
      expect(r.best, PayMethod.card);
      expect(r.forcedByPlace, isFalse);
    });

    test('place does not take cards: card is not a candidate', () {
      final r = th1000(
        withdrawalThb: 2000,
        place: const PlacePayment(cards: false),
      );
      expect(opt(r, PayMethod.card).accepted, Acceptance.no);
      // Card would be cheaper (25 vs 110) but it is not accepted.
      expect(r.best, PayMethod.cash);
      expect(r.forcedByPlace, isFalse);
    });

    test('cashOnly false alone leaves card acceptance unknown', () {
      final r = th1000(
        withdrawalThb: 2000,
        place: const PlacePayment(cashOnly: false),
      );
      expect(opt(r, PayMethod.card).accepted, Acceptance.unknown);
    });
  });

  group('missing evidence stays null', () {
    test('no card fee, no withdrawal: nothing comparable', () {
      final r = th1000(profile: const TravelerProfile());
      expect(opt(r, PayMethod.card).extraThb, isNull);
      expect(opt(r, PayMethod.cash).extraThb, isNull);
      expect(r.best, isNull);
      expect(r.sameCost, isFalse);
      expect(r.breakEvenWithdrawalThb, isNull);
    });

    test('no card fee: card null, cash alone is best', () {
      final r = th1000(
        withdrawalThb: 2000,
        profile: const TravelerProfile(atmFeePolicy: AtmFeePolicy.noFee),
      );
      expect(opt(r, PayMethod.card).extraThb, isNull);
      expect(opt(r, PayMethod.cash).extraThb, 110.00);
      expect(r.best, PayMethod.cash);
      expect(r.sameCost, isFalse);
      expect(r.breakEvenWithdrawalThb, isNull);
    });

    test('withdrawal null: cash null, card alone is best', () {
      final r = th1000();
      expect(opt(r, PayMethod.cash).extraThb, isNull);
      expect(opt(r, PayMethod.card).extraThb, 25.00);
      expect(r.best, PayMethod.card);
      // Break-even does not need a withdrawal size.
      expect(r.breakEvenWithdrawalThb, 8800.00);
    });

    test('withdrawal 0 is treated as unknown', () {
      final r = th1000(withdrawalThb: 0);
      expect(opt(r, PayMethod.cash).extraThb, isNull);
    });

    test('home ATM policy unknown: cash and break-even null', () {
      final r = th1000(
        withdrawalThb: 2000,
        profile: const TravelerProfile(cardFeePercent: 2.5),
      );
      expect(opt(r, PayMethod.cash).extraThb, isNull);
      expect(r.breakEvenWithdrawalThb, isNull);
      expect(r.best, PayMethod.card);
    });

    test('no country facts: local ATM fee unknown, cash null', () {
      final r = th1000(withdrawalThb: 2000, noFacts: true);
      expect(opt(r, PayMethod.cash).extraThb, isNull);
      expect(r.breakEvenWithdrawalThb, isNull);
    });

    test('facts without a sourced ATM fee: cash null, not zero', () {
      final r = th1000(
        withdrawalThb: 2000,
        facts: CountryPayFacts(
          country: 'TH',
          currency: 'THB',
          foreignCardAtmFee: null,
          atmOffersConversion: true,
        ),
      );
      expect(opt(r, PayMethod.cash).extraThb, isNull);
      expect(r.breakEvenWithdrawalThb, isNull);
    });

    test('fee in a third currency cannot be converted: cash null', () {
      final r = th1000(
        withdrawalThb: 2000,
        facts: CountryPayFacts(
          country: 'TH',
          currency: 'THB',
          foreignCardAtmFee: SourcedFee(
            value: 5,
            currency: 'USD',
            isPercent: false,
            source: 'Example',
            checked: '2026-10-15',
          ),
          atmOffersConversion: false,
        ),
      );
      expect(opt(r, PayMethod.cash).extraThb, isNull);
    });

    test('chargesFixed without homeToThb: cash null', () {
      final r = th1000(
        withdrawalThb: 2000,
        profile: const TravelerProfile(
          cardFeePercent: 2.5,
          atmFeePolicy: AtmFeePolicy.chargesFixed,
          atmFeeValue: 150,
        ),
      );
      expect(opt(r, PayMethod.cash).extraThb, isNull);
      expect(r.breakEvenWithdrawalThb, isNull);
    });

    test('chargesFixed without a value: cash null', () {
      final r = th1000(
        withdrawalThb: 2000,
        homeToThb: 1,
        profile: const TravelerProfile(
          cardFeePercent: 2.5,
          atmFeePolicy: AtmFeePolicy.chargesFixed,
        ),
      );
      expect(opt(r, PayMethod.cash).extraThb, isNull);
    });
  });

  group('JP: 5000 JPY at 1 THB = 4.6935 JPY', () {
    late PayRoute r;
    setUp(
      () => r = payRoute(
        amountLocal: 5000,
        localToThb: jpyToThb,
        place: PlacePayment.unknown,
        profile: const TravelerProfile(
          cardFeePercent: 2.5,
          atmFeePolicy: AtmFeePolicy.chargesFixed,
          atmFeeValue: 150,
        ),
        facts: jpFacts,
        withdrawalThb: 3000,
        homeToThb: 1,
      ),
    );

    test('amountThb 1065.30', () => expect(r.amountThb, 1065.30));
    test('card adds 26.63', () {
      expect(opt(r, PayMethod.card).extraThb, 26.63);
    });
    test('cash adds 61.59 (fees 110/4.6935 + 150 on a 3000 withdrawal)', () {
      expect(opt(r, PayMethod.cash).extraThb, 61.59);
      expect(
        opt(r, PayMethod.cash).basis,
        containsAll(['foreignCardAtmFee', 'homeAtmFee', 'withdrawal']),
      );
    });
    test('best is card', () => expect(r.best, PayMethod.card));
    test('break-even 6937.47 (173.4367 / 0.025)', () {
      expect(r.breakEvenWithdrawalThb, 6937.47);
    });
  });

  group('home bank policies', () {
    test('refundsFees: cash extra 0.00, break-even 0, cash is best', () {
      final r = th1000(
        withdrawalThb: 2000,
        profile: const TravelerProfile(
          cardFeePercent: 2.5,
          atmFeePolicy: AtmFeePolicy.refundsFees,
        ),
      );
      expect(opt(r, PayMethod.cash).extraThb, 0.00);
      expect(r.breakEvenWithdrawalThb, 0);
      expect(r.best, PayMethod.cash);
    });

    test('refundsFees with a large withdrawal is still 0.00', () {
      final r = th1000(
        withdrawalThb: 20000,
        profile: const TravelerProfile(
          cardFeePercent: 2.5,
          atmFeePolicy: AtmFeePolicy.refundsFees,
        ),
      );
      expect(opt(r, PayMethod.cash).extraThb, 0.00);
    });

    test('refundsFees without a withdrawal size: cash still null', () {
      final r = th1000(
        profile: const TravelerProfile(
          cardFeePercent: 2.5,
          atmFeePolicy: AtmFeePolicy.refundsFees,
        ),
      );
      expect(opt(r, PayMethod.cash).extraThb, isNull);
    });

    test('chargesPercent 1 %: fees 220 + 20 = 240, cash 120.00', () {
      final r = th1000(
        withdrawalThb: 2000,
        profile: const TravelerProfile(
          cardFeePercent: 2.5,
          atmFeePolicy: AtmFeePolicy.chargesPercent,
          atmFeeValue: 1,
        ),
      );
      expect(opt(r, PayMethod.cash).extraThb, 120.00);
      // Fixed 220 over (0.025 - 0.01).
      expect(r.breakEvenWithdrawalThb, 14666.67);
    });

    test('percent fee as high as the card fee: card never loses', () {
      final r = th1000(
        withdrawalThb: 2000,
        profile: const TravelerProfile(
          cardFeePercent: 1,
          atmFeePolicy: AtmFeePolicy.chargesPercent,
          atmFeeValue: 1,
        ),
      );
      expect(r.breakEvenWithdrawalThb, isNull);
    });

    test('card fee 0 %: break-even null', () {
      final r = th1000(
        withdrawalThb: 2000,
        profile: const TravelerProfile(
          cardFeePercent: 0,
          atmFeePolicy: AtmFeePolicy.noFee,
        ),
      );
      expect(opt(r, PayMethod.card).extraThb, 0.00);
      expect(r.breakEvenWithdrawalThb, isNull);
    });

    test('local ATM fee in percent: 1 % of 2000 = 20, cash 10.00', () {
      final r = th1000(
        withdrawalThb: 2000,
        facts: CountryPayFacts(
          country: 'TH',
          currency: 'THB',
          foreignCardAtmFee: SourcedFee(
            value: 1,
            currency: 'THB',
            isPercent: true,
            source: 'Example fee schedule',
            checked: '2026-10-15',
          ),
          atmOffersConversion: false,
        ),
      );
      expect(opt(r, PayMethod.cash).extraThb, 10.00);
      expect(r.best, PayMethod.cash);
    });
  });

  group('QR', () {
    test('sourced QR fee 1.0 % on 1000 THB adds 10.00 and can be best', () {
      final r = th1000(withdrawalThb: 2000, qrFeePercent: 1.0);
      final qr = opt(r, PayMethod.qr);
      expect(qr.extraThb, 10.00);
      expect(qr.accepted, Acceptance.unknown);
      expect(qr.basis, contains('qrFeePercent'));
      expect(r.best, PayMethod.qr);
    });

    test('QR is never accepted yes or no from Google data', () {
      final r = th1000(
        withdrawalThb: 2000,
        qrFeePercent: 1.0,
        place: const PlacePayment(cards: true, nfc: true),
      );
      expect(opt(r, PayMethod.qr).accepted, Acceptance.unknown);
    });

    test('QR within 0.50 of the card: same cost', () {
      // Card 25.00, QR 2.45 % = 24.50 -> difference 0.50.
      final r = th1000(withdrawalThb: 2000, qrFeePercent: 2.45);
      expect(opt(r, PayMethod.qr).extraThb, 24.50);
      expect(r.best, isNull);
      expect(r.sameCost, isTrue);
    });
  });

  group('invalid input', () {
    test('amount 0 throws', () {
      expect(() => th1000(amountLocal: 0), throwsArgumentError);
    });
    test('negative amount throws', () {
      expect(() => th1000(amountLocal: -5), throwsArgumentError);
    });
    test('rate 0 throws', () {
      expect(
        () => payRoute(
          amountLocal: 1000,
          localToThb: 0,
          place: PlacePayment.unknown,
          profile: card25NoFee,
        ),
        throwsArgumentError,
      );
    });
  });
}
