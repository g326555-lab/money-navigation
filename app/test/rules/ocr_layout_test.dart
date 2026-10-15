import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/ocr_layout.dart';

import 'fixtures/atm_ocr_real_ios.dart';

OcrLine line(
  String text,
  double left,
  double top,
  double right,
  double bottom,
) => OcrLine(text: text, left: left, top: top, right: right, bottom: bottom);

void main() {
  group('rowsFromLines: real iOS capture of the ATM prop', () {
    final rows = rowsFromLines(atmRealIosLines).split('\n');

    for (final expected in [
      'Withdrawal amount 4. 000 THB 137.17 USD',
      'Access fee 220 THB 7.54 USD',
      'Exchange rate 1 USD 30.86 THB',
      'Exchange rate markup 5.50 %',
      'Amount charged 4.220 THB 144.71 USD',
    ]) {
      test('has the row "$expected"', () => expect(rows, contains(expected)));
    }

    test('value rows appear top to bottom in screen order', () {
      final order = [
        'Withdrawal amount',
        'Access fee',
        'Exchange rate 1 USD',
        'Exchange rate markup',
        'Amount charged',
      ].map((label) => rows.indexWhere((r) => r.startsWith(label))).toList();
      expect(order, everyElement(greaterThanOrEqualTo(0)));
      expect(order, orderedEquals([...order]..sort()));
    });

    test('neighbouring rows are not merged', () {
      // Each value lands in exactly one row, and that row has one label.
      for (final value in [
        '4. 000 THB',
        '137.17 USD',
        '220 THB',
        '7.54 USD',
        '30.86 THB',
        '5.50 %',
        '4.220 THB',
        '144.71 USD',
      ]) {
        // Match after a space so "220 THB" does not match "4.220 THB".
        expect(
          rows.where((r) => ' $r'.contains(' $value')),
          hasLength(1),
          reason: value,
        );
      }
      final labels = [
        'Withdrawal amount',
        'Access fee',
        'Amount charged',
        'Exchange rate markup',
      ];
      for (final row in rows) {
        expect(
          labels.where(row.contains).length,
          lessThanOrEqualTo(1),
          reason: row,
        );
      }
      expect(rows.where((r) => r.contains('Exchange rate')), hasLength(2));
    });

    test('keeps lines that are not values (headers, buttons, credit)', () {
      final text = rows.join('\n');
      expect(text, contains('Cancel'));
      expect(text, contains('Photo: ASEAN NOW forum (aseannow. com)'));
      expect(text, contains('Accept without'));
      expect(text, contains('Accept with'));
    });

    test('does not depend on the input order of the lines', () {
      expect(
        rowsFromLines(atmRealIosLines.reversed.toList()),
        rowsFromLines(atmRealIosLines),
      );
    });
  });

  group('rowsFromLines: basics', () {
    test(
      'empty list gives an empty string',
      () => expect(rowsFromLines(const []), ''),
    );

    test('a single line gives its text', () {
      expect(
        rowsFromLines([line('Access fee', 300, 395, 522, 429)]),
        'Access fee',
      );
    });

    test('lines in one row are joined left to right with one space', () {
      expect(
        rowsFromLines([
          line('7.54 USD', 1470, 387, 1740, 427),
          line('Access fee', 304, 395, 522, 429),
          line('220 THB', 807, 387, 1051, 428),
        ]),
        'Access fee 220 THB 7.54 USD',
      );
    });

    test('rows are sorted top to bottom and joined with a newline', () {
      expect(
        rowsFromLines([
          line('Second', 0, 100, 100, 140),
          line('First', 0, 0, 100, 40),
        ]),
        'First\nSecond',
      );
    });
  });

  group('rowsFromLines: overlap threshold (30 % of the smaller height)', () {
    test(
      'tilted photo: a label 28 px lower than its value stays in the row',
      () {
        // Tightest real case: value 707-755 (48 px), label 735-779 (44 px).
        // 20 px overlap is 45 % of the smaller height.
        expect(
          rowsFromLines([
            line('144.71 USD', 1395, 707, 1733, 755),
            line('Amount charged', 322, 735, 645, 779),
          ]),
          'Amount charged 144.71 USD',
        );
      },
    );

    test('tilt tolerance: 40 px lines offset by 20 px (50 % overlap) join', () {
      expect(
        rowsFromLines([
          line('5.50 %', 1536, 600, 1734, 640),
          line('Exchange rate markup', 319, 620, 772, 660),
        ]),
        'Exchange rate markup 5.50 %',
      );
    });

    test('35 % overlap joins (above the 30 % threshold)', () {
      // 40 px lines offset by 26 px: 14 px overlap = 35 %.
      expect(
        rowsFromLines([
          line('5.50 %', 1536, 0, 1734, 40),
          line('Exchange rate markup', 319, 26, 772, 66),
        ]),
        'Exchange rate markup 5.50 %',
      );
    });

    test('little overlap (under 30 %) keeps two rows', () {
      // 40 px lines offset by 30 px: 10 px overlap = 25 %.
      expect(
        rowsFromLines([
          line('Upper', 500, 0, 600, 40),
          line('Lower', 0, 30, 100, 70),
        ]),
        'Upper\nLower',
      );
    });

    test('lines that do not overlap at all keep two rows', () {
      expect(
        rowsFromLines([line('A', 0, 0, 10, 40), line('B', 50, 45, 60, 85)]),
        'A\nB',
      );
    });
  });
}
