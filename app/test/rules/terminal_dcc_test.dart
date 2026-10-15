import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/exchange_rate.dart';
import 'package:money_navigation/rules/ocr_layout.dart';
import 'package:money_navigation/rules/terminal_dcc.dart';

import 'fixtures/terminal_ocr_real_ios.dart';

/// The fixed demo rate from assets/data/demo_rates.json: 1 THB = 4.6935 JPY.
final demoRate = RateQuote(
  base: 'THB',
  quote: 'JPY',
  rate: 4.6935,
  date: '2026-10-15',
  fetchedAt: DateTime.utc(2026, 10, 15),
);

/// A live-style rate on another day, to prove nothing is tied to the demo.
final liveRate = RateQuote(
  base: 'THB',
  quote: 'JPY',
  rate: 4.7085,
  date: '2026-10-06',
  fetchedAt: DateTime.utc(2026, 10, 6, 9),
);

/// The terminal as printed on the demo prop (CLAUDE.md "Demo data").
const demoRows = 'Select Currency\nF1:THB 12,851.82\nF2:JPY 58,000';

// Image center of the real capture: prints/demo-prints-A4.pdf page 2 at
// 200 dpi is 1654 x 2339 px.
const double _cx = 1654 / 2;
const double _cy = 2339 / 2;

/// Rotates a box about the image center by [degrees] (y grows downwards)
/// and returns its corners in ML Kit order: top-left, top-right,
/// bottom-right, bottom-left.
OcrQuad _rotatedQuad(OcrLine l, double degrees) {
  final t = degrees * math.pi / 180;
  (double, double) rotate(double x, double y) {
    final dx = x - _cx;
    final dy = y - _cy;
    return (
      _cx + dx * math.cos(t) - dy * math.sin(t),
      _cy + dx * math.sin(t) + dy * math.cos(t),
    );
  }

  return OcrQuad(
    text: l.text,
    corners: [
      rotate(l.left, l.top),
      rotate(l.right, l.top),
      rotate(l.right, l.bottom),
      rotate(l.left, l.bottom),
    ],
  );
}

void _expectDemoVerdict(DccVerdict? v) {
  expect(v, isNotNull);
  expect(v!.homeOption.key, 1);
  expect(v.localOption.key, 2);
  expect(v.homeOption.amount, closeTo(12851.82, 1e-9));
  expect(v.localOption.amount, closeTo(58000, 1e-9));
  expect(v.fairHomeAmount, closeTo(12357.52, 1e-9));
  expect(v.extraHome, closeTo(494.30, 1e-9));
  expect(v.markupPercent, closeTo(4.0, 0.01));
  expect(v.payLocal, isTrue);
}

void main() {
  group('readTerminalOptions', () {
    test('demo terminal: F1 THB 12,851.82 and F2 JPY 58,000 in key order', () {
      final options = readTerminalOptions(demoRows);
      expect(options, hasLength(2));
      expect(options[0].key, 1);
      expect(options[0].code, 'THB');
      expect(options[0].amount, closeTo(12851.82, 1e-9));
      expect(options[1].key, 2);
      expect(options[1].code, 'JPY');
      expect(options[1].amount, closeTo(58000, 1e-9));
    });

    test('real iOS capture: space after comma, F2 code and amount on '
        'separate lines, keypad labels ignored', () {
      final options = readTerminalOptions(rowsFromLines(terminalRealIosLines));
      expect(options, hasLength(2));
      expect(options[0].key, 1);
      expect(options[0].code, 'THB');
      expect(options[0].amount, closeTo(12851.82, 1e-9));
      expect(options[1].key, 2);
      expect(options[1].code, 'JPY');
      expect(options[1].amount, closeTo(58000, 1e-9));
    });

    test('"F2:PY" keeps the partial code and the amount', () {
      final options = readTerminalOptions('F1:THB 12,851.82\nF2:PY 58, 000');
      expect(options, hasLength(2));
      expect(options[1].key, 2);
      expect(options[1].code, 'PY');
      expect(options[1].amount, closeTo(58000, 1e-9));
    });

    test('"F2 : JPY" with spaces around the colon', () {
      final options = readTerminalOptions(
        'F1 : THB 12,851.82\nF2 : JPY 58,000',
      );
      expect(options, hasLength(2));
      expect(options[0].code, 'THB');
      expect(options[1].code, 'JPY');
      expect(options[1].amount, closeTo(58000, 1e-9));
    });

    test('options are returned in key order even if F2 is printed first', () {
      final options = readTerminalOptions('F2:JPY 58,000\nF1:THB 12,851.82');
      expect(options.map((o) => o.key), [1, 2]);
    });

    test('keypad labels alone ("F1", "F2", "F1 OR F2") are not options', () {
      expect(readTerminalOptions('F1 Qz ABC\nF2\nF1 OR F2 6'), isEmpty);
    });

    test('no option at all gives an empty list', () {
      expect(readTerminalOptions('Select Currency\nVISA'), isEmpty);
      expect(readTerminalOptions(''), isEmpty);
    });
  });

  group('judgeTerminal: demo terminal at the demo rate 4.6935', () {
    test(
      'printed text: fair 12,357.52 THB, about 494 THB extra, pay in JPY',
      () {
        _expectDemoVerdict(judgeTerminal(demoRows, rate: demoRate));
      },
    );

    test('extra cost rounds to about 494 THB', () {
      final v = judgeTerminal(demoRows, rate: demoRate)!;
      expect(v.extraHome.round(), 494);
    });

    test('verdict carries the reference rate and its date for the source '
        'line', () {
      final v = judgeTerminal(demoRows, rate: demoRate)!;
      expect(v.rate.rate, closeTo(4.6935, 1e-12));
      expect(v.rate.date, '2026-10-15');
    });

    test('real iOS capture via rowsFromLines gives the same verdict', () {
      _expectDemoVerdict(
        judgeTerminal(rowsFromLines(terminalRealIosLines), rate: demoRate),
      );
    });

    for (final degrees in [6.0, -6.0]) {
      test('real capture tilted $degrees deg, straightened, gives the same '
          'verdict', () {
        final quads = terminalRealIosLines
            .map((l) => _rotatedQuad(l, degrees))
            .toList();
        _expectDemoVerdict(
          judgeTerminal(rowsFromLines(straightenLines(quads)), rate: demoRate),
        );
      });
    }

    test('"F2:PY" (iOS dropped the J) gives the same verdict', () {
      _expectDemoVerdict(
        judgeTerminal('F1:THB 12, 851.82\nF2:PY 58, 000', rate: demoRate),
      );
    });

    test('home and local are decided from the amounts, not the codes, so a '
        'missing code still works', () {
      _expectDemoVerdict(
        judgeTerminal('F1: 12,851.82\nF2: 58,000', rate: demoRate),
      );
    });
  });

  group('judgeTerminal: edge cases', () {
    test('swapped order (F1 = JPY, F2 = THB) picks F1 as the local option', () {
      final v = judgeTerminal(
        'F1:JPY 58,000\nF2:THB 12,851.82',
        rate: demoRate,
      );
      expect(v, isNotNull);
      expect(v!.homeOption.key, 2);
      expect(v.localOption.key, 1);
      expect(v.homeOption.amount, closeTo(12851.82, 1e-9));
      expect(v.localOption.amount, closeTo(58000, 1e-9));
      expect(v.fairHomeAmount, closeTo(12357.52, 1e-9));
      expect(v.extraHome, closeTo(494.30, 1e-9));
      expect(v.payLocal, isTrue);
    });

    test('a fully read code that contradicts the amounts gives null', () {
      expect(
        judgeTerminal('F1:JPY 12,851.82\nF2:THB 58,000', rate: demoRate),
        isNull,
      );
    });

    test('only one option gives null', () {
      expect(judgeTerminal('F1:THB 12,851.82', rate: demoRate), isNull);
      expect(judgeTerminal('F2:JPY 58,000', rate: demoRate), isNull);
    });

    test('no option gives null', () {
      expect(judgeTerminal('Select Currency', rate: demoRate), isNull);
    });

    test('a missing amount gives null', () {
      expect(judgeTerminal('F1:THB 12,851.82\nF2:JPY', rate: demoRate), isNull);
    });

    test('amounts that fit neither assignment give null', () {
      expect(
        judgeTerminal('F1:THB 100\nF2:JPY 58,000', rate: demoRate),
        isNull,
      );
    });

    test('home amount below fair: pay in home currency, no extra cost', () {
      final v = judgeTerminal(
        'F1:THB 12,300.00\nF2:JPY 58,000',
        rate: demoRate,
      );
      expect(v, isNotNull);
      expect(v!.homeOption.key, 1);
      expect(v.localOption.key, 2);
      expect(v.fairHomeAmount, closeTo(12357.52, 1e-9));
      expect(v.extraHome, lessThanOrEqualTo(0));
      expect(v.extraHome, closeTo(-57.52, 1e-9));
      expect(v.payLocal, isFalse);
    });
  });

  group('judgeTerminal: other rate (no demo hard-coding)', () {
    test('live-style rate 4.7085 changes the fair amount to 12,318.15', () {
      final v = judgeTerminal(demoRows, rate: liveRate);
      expect(v, isNotNull);
      expect(v!.fairHomeAmount, closeTo(12318.15, 1e-9));
      expect(v.extraHome, closeTo(533.67, 1e-9));
      expect(v.markupPercent, closeTo(533.67 / 12318.15 * 100, 0.01));
      expect(v.payLocal, isTrue);
    });

    test('the verdict carries the live rate date, not the demo date', () {
      final v = judgeTerminal(demoRows, rate: liveRate)!;
      expect(v.rate.date, '2026-10-06');
      expect(v.rate.rate, closeTo(4.7085, 1e-12));
    });
  });

  group('judgeTerminal: codes must match the rate pair', () {
    test('the verdict follows the rate direction: a JPY-home traveler '
        '(rate.base JPY) gets JPY as home and paying in THB costs more', () {
      final inverted = RateQuote(
        base: 'JPY',
        quote: 'THB',
        rate: 1 / 4.6935,
        date: '2026-10-15',
        fetchedAt: DateTime.utc(2026, 10, 15),
      );
      final v = judgeTerminal(demoRows, rate: inverted);
      expect(v, isNotNull);
      expect(v!.homeOption.key, 2);
      expect(v.localOption.key, 1);
      expect(v.fairHomeAmount, closeTo(60320.02, 1e-9));
      expect(v.extraHome, closeTo(-2320.02, 1e-9));
      expect(v.payLocal, isFalse);
    });

    test('an unknown 3-letter home code gives null', () {
      expect(
        judgeTerminal('F1:XYZ 12,851.82\nF2:JPY 58,000', rate: demoRate),
        isNull,
      );
    });

    test('a 3-letter local code other than the rate quote gives null', () {
      expect(
        judgeTerminal('F1:THB 12,851.82\nF2:USD 58,000', rate: demoRate),
        isNull,
      );
    });

    test('a partial code that is not part of the expected code gives null', () {
      expect(
        judgeTerminal('F1:THB 12,851.82\nF2:US 58,000', rate: demoRate),
        isNull,
      );
    });

    test('a partial code that is part of the expected code is fine', () {
      _expectDemoVerdict(
        judgeTerminal('F1:THB 12,851.82\nF2:PY 58,000', rate: demoRate),
      );
    });
  });

  group('readTerminalOptions: repeated keys', () {
    test('a key read twice with different amounts is dropped', () {
      final options = readTerminalOptions(
        'F1:THB 12,851.82\nF2:JPY 58,000\nF1:THB 99,999.99',
      );
      expect(options, hasLength(1));
      expect(options.single.key, 2);
      expect(options.single.amount, closeTo(58000, 1e-9));
    });

    test('so the verdict is null when F1 conflicts', () {
      expect(
        judgeTerminal(
          'F1:THB 12,851.82\nF2:JPY 58,000\nF1:THB 99,999.99',
          rate: demoRate,
        ),
        isNull,
      );
    });

    test('and null when F2 conflicts', () {
      expect(
        judgeTerminal(
          'F1:THB 12,851.82\nF2:JPY 58,000\nF2:JPY 1',
          rate: demoRate,
        ),
        isNull,
      );
    });

    test('the same key repeated with the same amount is kept once', () {
      final text = 'F1:THB 12,851.82\nF2:JPY 58,000\nF1:THB 12,851.82';
      final options = readTerminalOptions(text);
      expect(options.map((o) => o.key), [1, 2]);
      expect(options[0].amount, closeTo(12851.82, 1e-9));
      _expectDemoVerdict(judgeTerminal(text, rate: demoRate));
    });
  });

  group('readTerminalOptions: amount shape', () {
    test('3+ decimals that are not a thousands group: no option', () {
      final options = readTerminalOptions('F1:THB 12851.8234\nF2:JPY 58,000');
      expect(options.where((o) => o.key == 1), isEmpty);
    });

    test('"58.000" with a thousands dot still reads 58000', () {
      final options = readTerminalOptions('F2:JPY 58.000');
      expect(options, hasLength(1));
      expect(options.single.key, 2);
      expect(options.single.amount, closeTo(58000, 1e-9));
    });
  });

  group(
    'readTerminalOptions: a dot with three digits is a thousands group',
    () {
      test('"12851.823" gives no F1 option', () {
        final options = readTerminalOptions('F1:THB 12851.823\nF2:JPY 58,000');
        expect(options.where((o) => o.key == 1), isEmpty);
      });

      test('"12,851.823" gives no F1 option', () {
        final options = readTerminalOptions('F1:THB 12,851.823\nF2:JPY 58,000');
        expect(options.where((o) => o.key == 1), isEmpty);
      });

      test('"58.000" alone is a thousands group: 58000', () {
        final options = readTerminalOptions('F1:THB 12,851.82\nF2:JPY 58.000');
        expect(options, hasLength(2));
        expect(options[1].amount, closeTo(58000, 1e-9));
      });
    },
  );
}
