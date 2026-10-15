import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/atm_conversion.dart';

import 'fixtures/atm_ocr_fixtures.dart';

/// The exact demo values printed on the ATM prop (CLAUDE.md "Demo data").
const demoReading = AtmScreenReading(
  withdrawalThb: 4000,
  accessFeeThb: 220,
  thbPerUsd: 30.86,
  markupPercent: 5.50,
  chargedThb: 4220,
  chargedUsd: 144.71,
);

void expectDemoReading(AtmScreenReading? r) {
  expect(r, isNotNull);
  expect(r!.withdrawalThb, closeTo(4000, 1e-9));
  expect(r.accessFeeThb, closeTo(220, 1e-9));
  expect(r.thbPerUsd, closeTo(30.86, 1e-9));
  expect(r.markupPercent, closeTo(5.50, 1e-9));
  expect(r.chargedThb, closeTo(4220, 1e-9));
  expect(r.chargedUsd, closeTo(144.71, 1e-9));
}

void main() {
  group('parseAtmScreen: demo ATM photo', () {
    test('block-ordered OCR with thousands dot reads every printed value', () {
      expectDemoReading(parseAtmScreen(atmOcrBlockOrder));
    });

    test('row-ordered OCR with comma separators reads every printed value', () {
      expectDemoReading(parseAtmScreen(atmOcrRowOrder));
    });

    test('charged USD is 144.71, not the with-conversion withdrawal 137.17',
        () {
      expect(parseAtmScreen(atmOcrBlockOrder)!.chargedUsd,
          closeTo(144.71, 1e-9));
    });

    test('"4.220 THB" is read as 4220, not 4.22', () {
      expect(parseAtmScreen(atmOcrBlockOrder)!.chargedThb, closeTo(4220, 1e-9));
    });
  });

  group('parseAtmScreen: other numbers (no demo hard-coding)', () {
    test('reads a different screen with its own values', () {
      final r = parseAtmScreen(atmOcrOtherNumbers);
      expect(r, isNotNull);
      expect(r!.withdrawalThb, closeTo(2000, 1e-9));
      expect(r.accessFeeThb, closeTo(220, 1e-9));
      expect(r.thbPerUsd, closeTo(32.50, 1e-9));
      expect(r.markupPercent, closeTo(4.00, 1e-9));
      expect(r.chargedThb, closeTo(2220, 1e-9));
      expect(r.chargedUsd, closeTo(71.04, 1e-9));
    });
  });

  group('parseAtmScreen: missing values return null, never a default', () {
    test('mark-up is optional: absent line gives markupPercent null', () {
      final r = parseAtmScreen(atmOcrNoMarkup);
      expect(r, isNotNull);
      expect(r!.markupPercent, isNull);
      expect(r.chargedUsd, closeTo(144.71, 1e-9));
    });
    test('missing "Amount charged" row gives null',
        () => expect(parseAtmScreen(atmOcrMissingCharged), isNull));
    test('missing exchange rate gives null',
        () => expect(parseAtmScreen(atmOcrMissingRate), isNull));
    test('missing charged USD gives null',
        () => expect(parseAtmScreen(atmOcrMissingChargedUsd), isNull));
    test('zero exchange rate gives null',
        () => expect(parseAtmScreen(atmOcrZeroRate), isNull));
    test('text that is not an ATM screen gives null',
        () => expect(parseAtmScreen(ocrNotAnAtm), isNull));
    test('empty text gives null', () => expect(parseAtmScreen(''), isNull));
  });

  group('evaluateAtm: demo verdict (CLAUDE.md exact numbers)', () {
    final v = evaluateAtm(demoReading);

    test('recommends declining the ATM conversion',
        () => expect(v.recommended, AtmChoice.declineConversion));
    test('extra cost of converting is 7.96 USD (2 dp)', () {
      expect(double.parse(v.extraCostUsd.toStringAsFixed(2)), 7.96);
    });
    test('extra cost of converting is about 246 THB (whole baht)', () {
      expect(v.extraCostThb.round(), 246);
      expect(v.extraCostThb, closeTo(245.7, 0.1));
    });
  });

  group('evaluateAtm: end to end from OCR text', () {
    test('block-ordered demo OCR gives 7.96 USD and about 246 THB', () {
      final v = evaluateAtm(parseAtmScreen(atmOcrBlockOrder)!);
      expect(v.recommended, AtmChoice.declineConversion);
      expect(double.parse(v.extraCostUsd.toStringAsFixed(2)), 7.96);
      expect(v.extraCostThb.round(), 246);
    });
    test('other-numbers screen gives 2.73 USD and about 89 THB', () {
      final v = evaluateAtm(parseAtmScreen(atmOcrOtherNumbers)!);
      expect(v.recommended, AtmChoice.declineConversion);
      expect(double.parse(v.extraCostUsd.toStringAsFixed(2)), 2.73);
      expect(v.extraCostThb.round(), 89);
    });
  });

  group('evaluateAtm: no false savings', () {
    test('charged USD equal to fair USD: no extra cost, no decline claim', () {
      // 3,086 THB / 30.86 = exactly 100.00 USD fair.
      final v = evaluateAtm(const AtmScreenReading(
        withdrawalThb: 2866,
        accessFeeThb: 220,
        thbPerUsd: 30.86,
        chargedThb: 3086,
        chargedUsd: 100.00,
      ));
      expect(v.recommended, AtmChoice.acceptConversion);
      expect(v.extraCostUsd, closeTo(0, 0.005));
      expect(v.extraCostThb, closeTo(0, 0.5));
    });

    test('conversion cheaper than fair: no positive extra cost claimed', () {
      final v = evaluateAtm(const AtmScreenReading(
        withdrawalThb: 2866,
        accessFeeThb: 220,
        thbPerUsd: 30.86,
        chargedThb: 3086,
        chargedUsd: 99.00,
      ));
      expect(v.recommended, AtmChoice.acceptConversion);
      expect(v.extraCostUsd, lessThanOrEqualTo(0));
    });
  });

  group('evaluateAtm: invalid rate is rejected', () {
    final rejected = throwsA(anyOf(isA<ArgumentError>(), isA<AssertionError>()));
    test('zero rate', () {
      expect(
          () => evaluateAtm(AtmScreenReading(
                withdrawalThb: 4000,
                accessFeeThb: 220,
                thbPerUsd: double.parse('0'),
                chargedThb: 4220,
                chargedUsd: 144.71,
              )),
          rejected);
    });
    test('negative rate', () {
      expect(
          () => evaluateAtm(AtmScreenReading(
                withdrawalThb: 4000,
                accessFeeThb: 220,
                thbPerUsd: double.parse('-30.86'),
                chargedThb: 4220,
                chargedUsd: 144.71,
              )),
          rejected);
    });
  });
}
