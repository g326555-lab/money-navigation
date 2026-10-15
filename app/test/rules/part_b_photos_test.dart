import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/exchange_board.dart';
import 'package:money_navigation/rules/exchange_rate.dart';
import 'package:money_navigation/rules/ocr_layout.dart';
import 'package:money_navigation/rules/terminal_dcc.dart';

import 'fixtures/exchange_board_ocr_real_ios.dart';
import 'fixtures/part_b_photos_real_ios.dart';

/// The fixed demo rate from assets/data/demo_rates.json: 1 THB = 4.6935 JPY.
final demoRate = RateQuote(
  base: 'THB',
  quote: 'JPY',
  rate: 4.6935,
  date: '2026-10-15',
  fetchedAt: DateTime.utc(2026, 10, 15),
);

void _expectDemoVerdict(DccVerdict? v) {
  expect(v, isNotNull);
  expect(v!.homeOption.key, 1);
  expect(v.localOption.key, 2);
  expect(v.homeOption.amount, closeTo(12851.82, 1e-9));
  expect(v.localOption.amount, closeTo(58000, 1e-9));
  expect(v.fairHomeAmount, closeTo(12357.52, 1e-9));
  expect(v.extraHome, closeTo(494.30, 1e-9));
  expect(v.payLocal, isTrue);
}

OcrLine _line(String text, double left, double top, {double width = 200}) =>
    OcrLine(
      text: text,
      left: left,
      top: top,
      right: left + width,
      bottom: top + 40,
    );

/// Labels and amounts on separate, misaligned lines, as in photo 155419:
/// each amount sits halfway between two label rows.
final _f1Label = _line('F1:THB', 100, 100);
final _f2Label = _line('F2:JPY', 100, 200);
final _f1Amount = _line('12,851.82', 400, 50);
final _f2Amount = _line('58, 000', 400, 150);

/// Buying notes / selling notes as printed on prints/demo-prints-A4.pdf
/// page 3, for every code on the board.
const _printed = <String, (double, double)>{
  'USD': (35.03, 36.10),
  'EUR': (45.72, 46.86),
  'GBP': (68.96, 70.90),
  'JPY': (0.2879, 0.2971),
  'SGD': (22.89, 23.59),
  'HKD': (4.47, 4.66),
  'AUD': (27.08, 27.97),
  'NZD': (24.18, 25.31),
  'CHF': (27.99, 28.81),
  'SEK': (4.89, 5.19),
  'DKK': (5.94, 6.29),
  'CAD': (29.65, 30.66),
  'NOK': (5.43, 5.76),
  'BRD': (22.10, 23.50),
  'IDR': (0.0025, 0.005),
  'MYR': (8.53, 10.76),
  'CNY': (3.70, 4.97),
  'KRW': (0.029, 0.043),
  'TWD': (0.88, 1.19),
  'AED': (7.75, 10.20),
  'BHD': (59.63, 96.33),
  'OMR': (59.41, 94.21),
  'QAR': (7.67, 10.22),
  'SAR': (7.58, 10.19),
  'ZAR': (3.65, 5.45),
};

/// Known limitations: reads that differ from the print and that no rule on
/// the board alone can see. Key is 'capture code', value is what is read.
const _knownMisreads = <String, (double, double)>{
  // OCR read selling "23.50" for printed 23.59: a single-digit misread.
  '200dpi SGD': (22.89, 23.50),
  // OCR read selling "30.60" for printed 30.66: a single-digit misread.
  '200dpi CAD': (29.65, 30.60),
  // Keystone photo: EUR selling ".86" was dropped and GBP selling 70.90 from
  // the next row was taken instead. Only boardRatePlausible catches it.
  '155435 EUR': (45.72, 70.90),
};

RateQuote _referenceAtPrintedMid(String code) {
  final (buying, selling) = _printed[code]!;
  return RateQuote(
    base: 'THB',
    quote: code,
    rate: 1 / ((buying + selling) / 2),
    date: '2026-10-15',
    fetchedAt: DateTime.utc(2026, 10, 15),
  );
}

final _boardCaptures = <String, String>{
  '200dpi': rowsFromLines(exchangeBoardRealIosLines),
  '155435': rowsFromLines(straightenLines(boardPhoto155435Quads)),
  '155438': rowsFromLines(straightenLines(boardPhoto155438Quads)),
  '155444': rowsFromLines(straightenLines(boardPhoto155444Quads)),
};

void main() {
  group('terminal photos (real Fold8 camera, real ML Kit)', () {
    test('155415 near frontal ("FL:THB"): judgeTerminalLines gives the demo '
        'verdict', () {
      _expectDemoVerdict(
        judgeTerminalLines(
          straightenLines(terminalPhoto155415Quads),
          rate: demoRate,
        ),
      );
    });

    test(
      '155415 near frontal: judgeTerminal on rows gives the demo verdict',
      () {
        _expectDemoVerdict(
          judgeTerminal(
            rowsFromLines(straightenLines(terminalPhoto155415Quads)),
            rate: demoRate,
          ),
        );
      },
    );

    test('155419 angled, labels and amounts split: judgeTerminalLines pairs '
        'them and gives the demo verdict', () {
      _expectDemoVerdict(
        judgeTerminalLines(
          straightenLines(terminalPhoto155419Quads),
          rate: demoRate,
        ),
      );
    });

    test('155419 angled: the misaligned rows alone give null', () {
      expect(
        judgeTerminal(
          rowsFromLines(straightenLines(terminalPhoto155419Quads)),
          rate: demoRate,
        ),
        isNull,
      );
    });

    test('155426 far ("12, B51.82"): judgeTerminalLines gives null', () {
      expect(
        judgeTerminalLines(
          straightenLines(terminalPhoto155426Quads),
          rate: demoRate,
        ),
        isNull,
      );
    });

    test('155426 far: judgeTerminal on rows gives null', () {
      expect(
        judgeTerminal(
          rowsFromLines(straightenLines(terminalPhoto155426Quads)),
          rate: demoRate,
        ),
        isNull,
      );
    });
  });

  group('board photos never give a wrong USD rate', () {
    for (final (name, quads) in [
      ('155435 keystone', boardPhoto155435Quads),
      ('155438 strong angle', boardPhoto155438Quads),
      ('155444 far, dots dropped', boardPhoto155444Quads),
    ]) {
      test('$name: USD gives null', () {
        expect(
          readExchangeBoard(rowsFromLines(straightenLines(quads)), code: 'USD'),
          isNull,
        );
      });
    }
  });

  group('judgeTerminalLines: synthetic label and amount lines', () {
    test('two labels and two amounts to their right pair top to bottom', () {
      _expectDemoVerdict(
        judgeTerminalLines([
          _f1Label,
          _f2Label,
          _f1Amount,
          _f2Amount,
        ], rate: demoRate),
      );
    });

    test('a line already holding label and amount is judged from rows', () {
      _expectDemoVerdict(
        judgeTerminalLines([
          _line('F1:THB 12,851.82', 100, 100),
          _line('F2:JPY 58,000', 100, 200),
        ], rate: demoRate),
      );
    });

    test('bare keypad digits do not count as amount lines', () {
      _expectDemoVerdict(
        judgeTerminalLines([
          _f1Label,
          _f2Label,
          _f1Amount,
          _f2Amount,
          _line('2', 600, 400, width: 30),
          _line('4 6', 600, 500, width: 60),
        ], rate: demoRate),
      );
    });

    test('a partial code label "F2:PY" still pairs', () {
      _expectDemoVerdict(
        judgeTerminalLines([
          _f1Label,
          _line('F2:PY', 100, 200),
          _f1Amount,
          _f2Amount,
        ], rate: demoRate),
      );
    });

    test('only one amount line gives null', () {
      expect(
        judgeTerminalLines([_f1Label, _f2Label, _f1Amount], rate: demoRate),
        isNull,
      );
    });

    test('three amount lines give null', () {
      expect(
        judgeTerminalLines([
          _f1Label,
          _f2Label,
          _f1Amount,
          _f2Amount,
          _line('1,234.00', 400, 300),
        ], rate: demoRate),
        isNull,
      );
    });

    test('only one label gives null', () {
      expect(
        judgeTerminalLines([_f1Label, _f1Amount, _f2Amount], rate: demoRate),
        isNull,
      );
    });

    test('two labels with the same key give null', () {
      expect(
        judgeTerminalLines([
          _f1Label,
          _line('F1:JPY', 100, 200),
          _f1Amount,
          _f2Amount,
        ], rate: demoRate),
        isNull,
      );
    });

    test('amounts left of the labels give null', () {
      expect(
        judgeTerminalLines([
          _f1Label,
          _f2Label,
          _line('12,851.82', 20, 50, width: 60),
          _line('58, 000', 20, 150, width: 60),
        ], rate: demoRate),
        isNull,
      );
    });

    test('no lines give null', () {
      expect(judgeTerminalLines(const [], rate: demoRate), isNull);
    });
  });

  group('judgeTerminalLines: reviewer swap repro', () {
    test('code-less labels with codes on separate lines and amounts in '
        'swapped order give null', () {
      expect(
        judgeTerminalLines([
          _line('F1:', 100, 455, width: 60),
          _line('THB', 170, 455, width: 70),
          _line('58, 000', 400, 420),
          _line('F2:', 100, 520, width: 60),
          _line('JPY', 170, 520, width: 70),
          _line('12,851.82', 400, 600),
        ], rate: demoRate),
        isNull,
      );
    });

    test('code-less labels paired with amounts give null', () {
      expect(
        judgeTerminalLines([
          _line('F1:', 100, 100, width: 60),
          _line('F2:', 100, 200, width: 60),
          _f1Amount,
          _f2Amount,
        ], rate: demoRate),
        isNull,
      );
    });
  });

  group('board truth table: every code is null or the printed rate', () {
    _boardCaptures.forEach((capture, rows) {
      for (final MapEntry(key: code, value: printed) in _printed.entries) {
        final known = _knownMisreads['$capture $code'];
        if (known != null) continue;
        test('$capture $code', () {
          final r = readExchangeBoard(rows, code: code);
          if (r == null) return;
          expect(r.code, code);
          expect(r.buying, closeTo(printed.$1, 1e-9));
          expect(r.selling, closeTo(printed.$2, 1e-9));
        });
      }
    });
  });

  group('board known limitations (documented, not fixed)', () {
    test('200dpi SGD: single-digit misread 23.50 for 23.59 is read and '
        'passes the reference check', () {
      final r = readExchangeBoard(_boardCaptures['200dpi']!, code: 'SGD')!;
      expect(r.buying, closeTo(22.89, 1e-9));
      expect(r.selling, closeTo(23.50, 1e-9));
      expect(
        boardRatePlausible(r, _referenceAtPrintedMid('SGD'), home: 'THB'),
        isTrue,
      );
    });

    test('200dpi CAD: single-digit misread 30.60 for 30.66 is read and '
        'passes the reference check', () {
      final r = readExchangeBoard(_boardCaptures['200dpi']!, code: 'CAD')!;
      expect(r.buying, closeTo(29.65, 1e-9));
      expect(r.selling, closeTo(30.60, 1e-9));
      expect(
        boardRatePlausible(r, _referenceAtPrintedMid('CAD'), home: 'THB'),
        isTrue,
      );
    });

    test('155435 EUR: wrong-row selling 70.90 is read by the board reader '
        'but rejected by boardRatePlausible', () {
      final r = readExchangeBoard(_boardCaptures['155435']!, code: 'EUR');
      if (r == null) return; // A stricter reader is also acceptable.
      expect(r.buying, closeTo(45.72, 1e-9));
      expect(r.selling, closeTo(70.90, 1e-9));
      expect(
        boardRatePlausible(r, _referenceAtPrintedMid('EUR'), home: 'THB'),
        isFalse,
      );
    });
  });

  group('readCheckedBoardRate: what the screen uses', () {
    RateQuote thbTo(String code, double rate) => RateQuote(
      base: 'THB',
      quote: code,
      rate: rate,
      date: '2026-10-15',
      fetchedAt: DateTime.utc(2026, 10, 15),
    );

    test('155435 EUR against THB->EUR 0.0216 gives null, never 45.72 / '
        '70.90', () {
      expect(
        readCheckedBoardRate(
          _boardCaptures['155435']!,
          code: 'EUR',
          reference: thbTo('EUR', 0.0216),
          home: 'THB',
        ),
        isNull,
      );
    });

    test(
      '200 dpi USD against the demo THB->USD 0.02978 reads 35.03 / 36.10',
      () {
        final r = readCheckedBoardRate(
          _boardCaptures['200dpi']!,
          code: 'USD',
          reference: thbTo('USD', 0.02978),
          home: 'THB',
        );
        expect(r, isNotNull);
        expect(r!.buying, closeTo(35.03, 1e-9));
        expect(r.selling, closeTo(36.10, 1e-9));
      },
    );

    test('"USD 3503 3610" gives null', () {
      expect(
        readCheckedBoardRate(
          'USD 3503 3610',
          code: 'USD',
          reference: thbTo('USD', 0.02978),
          home: 'THB',
        ),
        isNull,
      );
    });

    test('a reference for another currency gives null', () {
      expect(
        readCheckedBoardRate(
          _boardCaptures['200dpi']!,
          code: 'USD',
          reference: thbTo('EUR', 0.0216),
          home: 'THB',
        ),
        isNull,
      );
    });
  });

  group('checked board truth table: null or the printed rate', () {
    const knownCheckedMisreads = {'200dpi SGD', '200dpi CAD'};
    _boardCaptures.forEach((capture, rows) {
      for (final MapEntry(key: code, value: printed) in _printed.entries) {
        if (knownCheckedMisreads.contains('$capture $code')) continue;
        test('$capture $code', () {
          final r = readCheckedBoardRate(
            rows,
            code: code,
            reference: _referenceAtPrintedMid(code),
            home: 'THB',
          );
          if (r == null) return;
          expect(r.code, code);
          expect(r.buying, closeTo(printed.$1, 1e-9));
          expect(r.selling, closeTo(printed.$2, 1e-9));
        });
      }
    });

    for (final (code, buying, selling) in [
      ('SGD', 22.89, 23.50),
      ('CAD', 29.65, 30.60),
    ]) {
      test('known limitation: 200dpi $code single-digit misread '
          '$buying / $selling passes the check', () {
        final r = readCheckedBoardRate(
          _boardCaptures['200dpi']!,
          code: code,
          reference: _referenceAtPrintedMid(code),
          home: 'THB',
        );
        expect(r, isNotNull);
        expect(r!.buying, closeTo(buying, 1e-9));
        expect(r.selling, closeTo(selling, 1e-9));
      });
    }
  });
}
