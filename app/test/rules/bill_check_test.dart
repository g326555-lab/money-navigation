import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/bill_check.dart';
import 'package:money_navigation/rules/ocr_layout.dart';

import 'fixtures/atm_ocr_real_ios.dart';

// Real Cloud Vision output of a printed Black Canyon bill (Bangkok, 2014).
// flutter test runs from app/, so the path is relative to app/.
const String _fixturePath = 'test/rules/fixtures/raw/bill_vision_lines.json';

Map<String, dynamic> _loadFixture() =>
    jsonDecode(File(_fixturePath).readAsStringSync()) as Map<String, dynamic>;

List<Map<String, dynamic>> _fixtureLines(Map<String, dynamic> json) =>
    (json['lines'] as List).cast<Map<String, dynamic>>();

/// Same fixture without the lines whose text is in [texts].
Map<String, dynamic> _fixtureWithout(Set<String> texts) {
  final json = _loadFixture();
  return {
    ...json,
    'lines': _fixtureLines(json)
        .where((l) => !texts.contains(l['text']))
        .toList(),
  };
}

/// Same fixture with one line's text replaced.
Map<String, dynamic> _fixtureReplacing(String from, String to) {
  final json = _loadFixture();
  return {
    ...json,
    'lines': [
      for (final l in _fixtureLines(json))
        l['text'] == from ? {...l, 'text': to} : l,
    ],
  };
}

/// Rotates every corner by [degrees] about the center of all corners
/// (y grows downwards, same convention as ocr_straighten_test.dart).
Map<String, dynamic> _rotatedFixture(double degrees) {
  final json = _loadFixture();
  final lines = _fixtureLines(json);
  final xs = [
    for (final l in lines)
      for (final c in l['corners'] as List) (c as List)[0] as num,
  ];
  final ys = [
    for (final l in lines)
      for (final c in l['corners'] as List) (c as List)[1] as num,
  ];
  final cx = (xs.reduce(math.min) + xs.reduce(math.max)) / 2;
  final cy = (ys.reduce(math.min) + ys.reduce(math.max)) / 2;
  final t = degrees * math.pi / 180;
  return {
    ...json,
    'lines': [
      for (final l in lines)
        {
          'text': l['text'],
          'corners': [
            for (final c in l['corners'] as List)
              () {
                final dx = ((c as List)[0] as num) - cx;
                final dy = (c[1] as num) - cy;
                return [
                  cx + dx * math.cos(t) - dy * math.sin(t),
                  cy + dx * math.sin(t) + dy * math.cos(t),
                ];
              }(),
          ],
        },
    ],
  };
}

/// A clean bill as OCR lines: each row is a label on the left and its value
/// on the right, both on the same baseline.
List<OcrLine> _bill(List<(String, String?)> rows) {
  final lines = <OcrLine>[];
  for (var i = 0; i < rows.length; i++) {
    final top = 100.0 + i * 50;
    final (label, value) = rows[i];
    lines.add(
      OcrLine(text: label, left: 40, top: top, right: 400, bottom: top + 36),
    );
    if (value != null) {
      lines.add(
        OcrLine(text: value, left: 600, top: top, right: 760, bottom: top + 36),
      );
    }
  }
  return lines;
}

/// One OCR line per printed row, e.g. "Service 10% 184.50".
List<OcrLine> _rows(List<String> rows) => [
  for (var i = 0; i < rows.length; i++)
    OcrLine(
      text: rows[i],
      left: 40,
      top: 100.0 + i * 50,
      right: 760,
      bottom: 136.0 + i * 50,
    ),
];

void _expectRealBill(BillCheck? r) {
  expect(r, isNotNull);
  expect(r!.kind, BillKind.serviceCharge);
  expect(r.subtotal!, closeTo(225.00, 1e-9));
  expect(r.discount, isNotNull);
  expect(r.discount!, closeTo(13.00, 1e-9));
  expect(r.serviceCharge!, closeTo(21.00, 1e-9));
  expect(r.servicePercent!, closeTo(10, 1e-9));
  expect(r.total, closeTo(233.00, 1e-9));
  expect(r.vat, isNotNull);
  expect(r.vat!, closeTo(15.24, 1e-9));
  expect(r.vatPercent, isNotNull);
  expect(r.vatPercent!, closeTo(7, 1e-9));
  expect(r.beforeVat, isNotNull);
  expect(r.beforeVat!, closeTo(217.76, 1e-9));
  expect(r.vatIncluded, isTrue);
  expect(r.vatAddedOnTop, isFalse);
  expect(r.serviceAddedOnTop, isTrue);
  expect(r.nothingAdded, isFalse);
  expect(r.itemCount, isNull);
}

void main() {
  group(
    'Real Cloud Vision bill (garbled labels, values in their own column)',
    () {
      test('checkBillFromVision reads 225.00 / 13.00 / 21.00 (10%) / 233.00 / '
          'VAT 15.24 (7%) / before VAT 217.76', () {
        _expectRealBill(checkBillFromVision(_loadFixture()));
      });

      test('item amounts 140.00 and "85,00", cash 300 and change "67,00" are '
          'not picked as bill totals', () {
        final r = checkBillFromVision(_loadFixture());
        expect(r, isNotNull);
        for (final v in [140.0, 85.0, 300.0, 67.0]) {
          expect(r!.subtotal, isNot(closeTo(v, 1e-9)));
          expect(r.total, isNot(closeTo(v, 1e-9)));
        }
      });

      for (final degrees in [4.0, -4.0]) {
        test('photo rotated $degrees deg about the image center gives the same '
            'result', () {
          _expectRealBill(checkBillFromVision(_rotatedFixture(degrees)));
        });
      }

      test('checkBillFromVision equals checkBill(straightenLines(...))', () {
        final quads = [
          for (final l in _fixtureLines(_loadFixture()))
            OcrQuad(
              text: l['text'] as String,
              corners: [
                for (final c in l['corners'] as List)
                  (
                    ((c as List)[0] as num).toDouble(),
                    (c[1] as num).toDouble(),
                  ),
              ],
            ),
        ];
        _expectRealBill(checkBill(straightenLines(quads)));
      });
    },
  );

  group('Arithmetic must verify, otherwise null (never guess)', () {
    test('total tampered 233.00 -> 243.00 gives null', () {
      expect(
        checkBillFromVision(_fixtureReplacing('233.00', '243.00')),
        isNull,
      );
    });

    // Total 262 also fits VAT-inside (17.14 / 244.86) and 244.86 + 17.14 sums
    // to it, but a printed service percent that fails to verify is ambiguous,
    // so neither vatIncluded nor itemsOnly may claim this bill.
    test('service charge that is not 10% of (subtotal - discount) gives null '
        'even though subtotal - discount + service == total and VAT fits', () {
      // 225 - 13 + 50 = 262; 262 * 7 / 107 = 17.14; 262 - 17.14 = 244.86.
      final lines = _bill([
        ('Subtotal', '225.00'),
        ('Discount', '13.00'),
        ('Service charge 10%', '50.00'),
        ('Before VAT', '244.86'),
        ('VAT 7%', '17.14'),
        ('Total', '262.00'),
      ]);
      expect(checkBill(lines), isNull);
    });

    test(
      'no service percent printed and amounts do not balance gives null',
      () {
        final lines = _bill([
          ('Subtotal', '225.00'),
          ('Discount', '13.00'),
          ('Service charge', '30.00'),
          ('Total', '199.00'),
        ]);
        expect(checkBill(lines), isNull);
      },
    );

    test('empty lines give null', () {
      expect(checkBill(const []), isNull);
    });

    test('empty Vision JSON gives null', () {
      expect(
        checkBillFromVision(<String, dynamic>{'lines': <dynamic>[]}),
        isNull,
      );
    });
  });

  group('Clean synthetic bills', () {
    test('label and value on one row gives the real bill numbers', () {
      final lines = _bill([
        ('Subtotal', '225.00'),
        ('Discount', '13.00'),
        ('Service charge 10%', '21.00'),
        ('Before VAT', '217.76'),
        ('VAT 7%', '15.24'),
        ('Total', '233.00'),
      ]);
      _expectRealBill(checkBill(lines));
    });

    test(
      'no discount: 200.00 + 10% 20.00 = 220.00, VAT 14.39, before 205.61',
      () {
        final r = checkBill(
          _bill([
            ('Subtotal', '200.00'),
            ('Service charge 10%', '20.00'),
            ('Before VAT', '205.61'),
            ('VAT 7%', '14.39'),
            ('Total', '220.00'),
          ]),
        );
        expect(r, isNotNull);
        expect(r!.kind, BillKind.serviceCharge);
        expect(r.subtotal!, closeTo(200.00, 1e-9));
        expect(r.discount, isNull);
        expect(r.serviceCharge!, closeTo(20.00, 1e-9));
        expect(r.servicePercent!, closeTo(10, 1e-9));
        expect(r.total, closeTo(220.00, 1e-9));
        expect(r.vat!, closeTo(14.39, 1e-9));
        expect(r.vatPercent!, closeTo(7, 1e-9));
        expect(r.beforeVat!, closeTo(205.61, 1e-9));
        expect(r.vatIncluded, isTrue);
        expect(r.serviceAddedOnTop, isTrue);
      },
    );
  });

  group('VAT missing: the service-charge finding still stands', () {
    test(
      'real fixture without the VAT line keeps service, VAT fields null',
      () {
        final r = checkBillFromVision(_fixtureWithout({'ภาษี 7%', '15.24'}));
        expect(r, isNotNull);
        expect(r!.kind, BillKind.serviceCharge);
        expect(r.subtotal!, closeTo(225.00, 1e-9));
        expect(r.discount!, closeTo(13.00, 1e-9));
        expect(r.serviceCharge!, closeTo(21.00, 1e-9));
        expect(r.servicePercent!, closeTo(10, 1e-9));
        expect(r.total, closeTo(233.00, 1e-9));
        expect(r.vat, isNull);
        expect(r.vatPercent, isNull);
        expect(r.beforeVat, isNull);
        expect(r.vatIncluded, isFalse);
        expect(r.serviceAddedOnTop, isTrue);
      },
    );

    test('synthetic bill with no VAT rows at all', () {
      final r = checkBill(
        _bill([
          ('Subtotal', '200.00'),
          ('Service charge 10%', '20.00'),
          ('Total', '220.00'),
        ]),
      );
      expect(r, isNotNull);
      expect(r!.kind, BillKind.serviceCharge);
      expect(r.subtotal!, closeTo(200.00, 1e-9));
      expect(r.serviceCharge!, closeTo(20.00, 1e-9));
      expect(r.total, closeTo(220.00, 1e-9));
      expect(r.vat, isNull);
      expect(r.vatPercent, isNull);
      expect(r.beforeVat, isNull);
      expect(r.vatIncluded, isFalse);
    });
  });

  group('OCR number quirks', () {
    test('thousands separators and an item line "85,00" do not break it; the '
        'item 1,140.00 is not taken as subtotal', () {
      // 1225.00 + 122.50 = 1347.50; 1347.50 * 7 / 107 = 88.15; 1347.50 - 88.15 = 1259.35.
      final r = checkBill(
        _bill([
          ('Set menu', '1,140.00'),
          ('Iced coffee 85,00', null),
          ('Subtotal', '1,225.00'),
          ('Service charge 10%', '122.50'),
          ('Before VAT', '1,259.35'),
          ('VAT 7%', '88.15'),
          ('Total', '1,347.50'),
        ]),
      );
      expect(r, isNotNull);
      expect(r!.kind, BillKind.serviceCharge);
      expect(r.subtotal!, closeTo(1225.00, 1e-9));
      expect(r.discount, isNull);
      expect(r.serviceCharge!, closeTo(122.50, 1e-9));
      expect(r.servicePercent!, closeTo(10, 1e-9));
      expect(r.total, closeTo(1347.50, 1e-9));
      expect(r.vat!, closeTo(88.15, 1e-9));
      expect(r.beforeVat!, closeTo(1259.35, 1e-9));
      expect(r.vatIncluded, isTrue);
    });

    test('only stray comma-decimal amounts ("85,00", "67,00") give null '
        'without throwing', () {
      final lines = _bill([
        ('Iced coffee', '85,00'),
        ('Change(Baht):', '67,00'),
        ('Cash(THA):', '300'),
      ]);
      expect(() => checkBill(lines), returnsNormally);
      expect(checkBill(lines), isNull);
    });
  });

  group('Not a bill', () {
    test('real iOS OCR of the ATM demo print gives null', () {
      expect(checkBill(atmRealIosLines), isNull);
    });

    test('USD amounts that balance with a printed 5.50% give null '
        '(137.17 + 7.54 = 144.71)', () {
      final lines = _bill([
        ('Amount', '137.17 USD'),
        ('Fee 5.50%', null),
        ('Fee', '7.54 USD'),
        ('Charged', '144.71 USD'),
      ]);
      expect(checkBill(lines), isNull);
    });

    test('the real-bill numbers tagged THB still verify', () {
      final lines = _bill([
        ('Subtotal', '225.00 THB'),
        ('Discount', '13.00 THB'),
        ('Service charge 10%', '21.00 THB'),
        ('Before VAT', '217.76 THB'),
        ('VAT 7%', '15.24 THB'),
        ('Total', '233.00 THB'),
      ]);
      _expectRealBill(checkBill(lines));
    });
  });

  group('Reviewer false picks', () {
    test('cash and change after the total are not picked: 1,845.00 + 10% '
        '184.50 = 2,029.50, VAT 132.77, before 1,896.73', () {
      final r = checkBill(
        _rows([
          'Item 0 255.00',
          'Item 1 1,590.00',
          'Subtotal 1,845.00',
          'Service 10% 184.50',
          'Before VAT 1,896.73',
          'VAT 7% 132.77',
          'Total 2,029.50',
          'Cash 2,100.00',
          'Change 70.50',
        ]),
      );
      expect(r, isNotNull);
      expect(r!.kind, BillKind.serviceCharge);
      expect(r.subtotal!, closeTo(1845.00, 1e-9));
      expect(r.discount, isNull);
      expect(r.serviceCharge!, closeTo(184.50, 1e-9));
      expect(r.servicePercent!, closeTo(10, 1e-9));
      expect(r.total, closeTo(2029.50, 1e-9));
      expect(r.vat!, closeTo(132.77, 1e-9));
      expect(r.beforeVat!, closeTo(1896.73, 1e-9));
      expect(r.vatIncluded, isTrue);
    });

    test('a percent discount is never read as a service charge: the receipt '
        'is vatIncluded (545.00, VAT 35.65, before 509.35), nothing added', () {
      // 545 * 7 / 107 = 35.65; 545 - 35.65 = 509.35. Cash 600 is not the total.
      final r = checkBill(
        _rows([
          'Item 320.00',
          'Item 285.00',
          'Member discount 10% 60.00',
          'Total 545.00',
          'VAT 7% 35.65',
          'Before VAT 509.35',
          'Cash 600.00',
          'Change 55.00',
        ]),
      );
      expect(r, isNotNull);
      expect(r!.kind, BillKind.vatIncluded);
      expect(r.serviceCharge, isNull);
      expect(r.servicePercent, isNull);
      expect(r.serviceAddedOnTop, isFalse);
      expect(r.total, closeTo(545.00, 1e-9));
      expect(r.vat!, closeTo(35.65, 1e-9));
      expect(r.beforeVat!, closeTo(509.35, 1e-9));
      expect(r.vatIncluded, isTrue);
      expect(r.vatAddedOnTop, isFalse);
      expect(r.nothingAdded, isTrue);
    });

    // 201 + 21 = 222 would also pass the itemsOnly sum, but a printed service
    // percent that fails to verify is ambiguous: it must not become
    // "nothing added".
    test('service 21.00 on subtotal 201.00 is not rounding of 20.10: null', () {
      expect(
        checkBill(
          _rows(['Subtotal 201.00', 'Service 10% 21.00', 'Total 222.00']),
        ),
        isNull,
      );
    });

    test('70 item lines plus the real summary verify in under 50 ms', () {
      final lines = _rows([
        for (var i = 0; i < 70; i++)
          'Item $i ${(30 + i * 1.25).toStringAsFixed(2)}',
        'Subtotal 225.00',
        'Discount 13.00',
        'Service charge 10% 21.00',
        'Before VAT 217.76',
        'VAT 7% 15.24',
        'Total 233.00',
      ]);
      checkBill(lines); // warm-up so JIT compilation is not timed
      final sw = Stopwatch()..start();
      final r = checkBill(lines);
      sw.stop();
      _expectRealBill(r);
      expect(sw.elapsedMilliseconds, lessThan(50));
    });
  });

  group('Kind: VAT added on top (rule 2)', () {
    test('Food 300.00 / Subtotal 300.00 / VAT 7% 21.00 / Total 321.00', () {
      final r = checkBill(
        _rows([
          'Food 300.00',
          'Subtotal 300.00',
          'VAT 7% 21.00',
          'Total 321.00',
        ]),
      );
      expect(r, isNotNull);
      expect(r!.kind, BillKind.vatOnTop);
      expect(r.subtotal!, closeTo(300.00, 1e-9));
      expect(r.vat!, closeTo(21.00, 1e-9));
      expect(r.vatPercent!, closeTo(7, 1e-9));
      expect(r.beforeVat!, closeTo(300.00, 1e-9));
      expect(r.total, closeTo(321.00, 1e-9));
      expect(r.serviceCharge, isNull);
      expect(r.servicePercent, isNull);
      expect(r.vatAddedOnTop, isTrue);
      expect(r.vatIncluded, isFalse);
      expect(r.serviceAddedOnTop, isFalse);
      expect(r.nothingAdded, isFalse);
    });

    test('restaurant without discount: 3 dishes, Subtotal 1,250.00 + VAT 7% '
        '87.50 = 1,337.50, cash and change after', () {
      final r = checkBill(
        _bill([
          ('Tom yum goong', '450.00'),
          ('Green curry', '380.00'),
          ('Grilled fish', '420.00'),
          ('Subtotal', '1,250.00'),
          ('VAT 7%', '87.50'),
          ('Total', '1,337.50'),
          ('Cash', '1,500.00'),
          ('Change', '162.50'),
        ]),
      );
      expect(r, isNotNull);
      expect(r!.kind, BillKind.vatOnTop);
      expect(r.subtotal!, closeTo(1250.00, 1e-9));
      expect(r.discount, isNull);
      expect(r.vat!, closeTo(87.50, 1e-9));
      expect(r.beforeVat!, closeTo(1250.00, 1e-9));
      expect(r.total, closeTo(1337.50, 1e-9));
      expect(r.vatAddedOnTop, isTrue);
      expect(r.vatIncluded, isFalse);
      expect(r.nothingAdded, isFalse);
    });

    test('satang-exact VAT on top: 233.50 * 7% = 16.345 -> 16.35 (or 16.34), '
        'total 249.85', () {
      final r = checkBill(
        _rows([
          'Khao soi 150.00',
          'Mango sticky rice 83.50',
          'Subtotal 233.50',
          'VAT 7% 16.35',
          'Total 249.85',
        ]),
      );
      expect(r, isNotNull);
      expect(r!.kind, BillKind.vatOnTop);
      expect(r.subtotal!, closeTo(233.50, 1e-9));
      expect(r.vat!, closeTo(16.35, 1e-9));
      expect(r.total, closeTo(249.85, 1e-9));
      expect(r.itemCount, 2);
    });
  });

  group('Kind: VAT included in the total (rule 3)', () {
    test('7-Eleven style: items 45 + 62 = Total 107.00, Vatable 100.00, '
        'VAT 7% 7.00, cash 200 / change 93', () {
      final r = checkBill(
        _rows([
          'Item 45.00',
          'Item 62.00',
          'Total 107.00',
          'Vatable 100.00',
          'VAT 7% 7.00',
          'Cash 200.00',
          'Change 93.00',
        ]),
      );
      expect(r, isNotNull);
      expect(r!.kind, BillKind.vatIncluded);
      expect(r.total, closeTo(107.00, 1e-9));
      expect(r.vat!, closeTo(7.00, 1e-9));
      expect(r.vatPercent!, closeTo(7, 1e-9));
      expect(r.beforeVat!, closeTo(100.00, 1e-9));
      expect(r.itemCount, 2);
      expect(r.subtotal!, closeTo(107.00, 1e-9));
      expect(r.serviceCharge, isNull);
      expect(r.vatIncluded, isTrue);
      expect(r.vatAddedOnTop, isFalse);
      expect(r.serviceAddedOnTop, isFalse);
      expect(r.nothingAdded, isTrue);
    });

    test('Vatable line printed before the total: 45 / 62 / Vatable 100.00 / '
        'VAT 7% 7.00 / Total 107.00', () {
      final r = checkBill(
        _rows([
          'Item 45.00',
          'Item 62.00',
          'Vatable 100.00',
          'VAT 7% 7.00',
          'Total 107.00',
          'Cash 200.00',
          'Change 93.00',
        ]),
      );
      expect(r, isNotNull);
      expect(r!.kind, BillKind.vatIncluded);
      expect(r.total, closeTo(107.00, 1e-9));
      expect(r.vat!, closeTo(7.00, 1e-9));
      expect(r.beforeVat!, closeTo(100.00, 1e-9));
      expect(r.vatIncluded, isTrue);
      expect(r.nothingAdded, isTrue);
      // Cash 200 and change 93 are never the total.
      expect(r.total, isNot(closeTo(200.00, 1e-9)));
    });

    test('items that do not sum to the total leave itemCount null but VAT '
        'still verifies: Total 85.00, VAT 5.56, Vatable 79.44', () {
      // 85 * 7 / 107 = 5.5607 -> 5.56; 85 - 5.56 = 79.44.
      final r = checkBill(
        _rows([
          'Item 40.00',
          'Item 30.00',
          'Total 85.00',
          'Vatable 79.44',
          'VAT 7% 5.56',
        ]),
      );
      expect(r, isNotNull);
      expect(r!.kind, BillKind.vatIncluded);
      expect(r.total, closeTo(85.00, 1e-9));
      expect(r.vat!, closeTo(5.56, 1e-9));
      expect(r.beforeVat!, closeTo(79.44, 1e-9));
      expect(r.itemCount, isNull);
    });

    test('a wrong VAT amount (Total 107.00 / VAT 7% 8.00 / Vatable 99.00) '
        'gives null: the printed tax lines do not add up, so nothing is '
        'verified', () {
      final r = checkBill(
        _rows([
          'Item 45.00',
          'Item 62.00',
          'Total 107.00',
          'VAT 7% 8.00',
          'Vatable 99.00',
        ]),
      );
      expect(r, isNull);
    });
  });

  group('Kind: items only (rule 4)', () {
    test('Pad thai 60.00 / Iced tea 25.00 / Total 85.00 / Cash 100.00 / '
        'Change 15.00', () {
      final r = checkBill(
        _rows([
          'Pad thai 60.00',
          'Iced tea 25.00',
          'Total 85.00',
          'Cash 100.00',
          'Change 15.00',
        ]),
      );
      expect(r, isNotNull);
      expect(r!.kind, BillKind.itemsOnly);
      expect(r.total, closeTo(85.00, 1e-9));
      expect(r.subtotal!, closeTo(85.00, 1e-9));
      expect(r.itemCount, 2);
      expect(r.discount, isNull);
      expect(r.serviceCharge, isNull);
      expect(r.vat, isNull);
      expect(r.vatPercent, isNull);
      expect(r.beforeVat, isNull);
      expect(r.serviceAddedOnTop, isFalse);
      expect(r.vatIncluded, isFalse);
      expect(r.vatAddedOnTop, isFalse);
      expect(r.nothingAdded, isTrue);
    });

    test('cash 100.00 is not taken as the total even though 85 + 15 = 100', () {
      final r = checkBill(
        _bill([
          ('Pad thai', '60.00'),
          ('Iced tea', '25.00'),
          ('Total', '85.00'),
          ('Cash', '100.00'),
          ('Change', '15.00'),
        ]),
      );
      expect(r, isNotNull);
      expect(r!.kind, BillKind.itemsOnly);
      expect(r.total, closeTo(85.00, 1e-9));
      expect(r.total, isNot(closeTo(100.00, 1e-9)));
      expect(r.itemCount, 2);
    });

    test(
      'single item printed again as the total: Latte 85.00 / Total 85.00',
      () {
        final r = checkBill(_rows(['Latte 85.00', 'Total 85.00']));
        expect(r, isNotNull);
        expect(r!.kind, BillKind.itemsOnly);
        expect(r.total, closeTo(85.00, 1e-9));
        expect(r.subtotal!, closeTo(85.00, 1e-9));
        expect(r.itemCount, 1);
        expect(r.vat, isNull);
        expect(r.nothingAdded, isTrue);
      },
    );

    test('four items with thousands separators: 1,200 + 350 + 89.50 + 60.50 '
        '= 1,700.00, cash 2,000 / change 300', () {
      final r = checkBill(
        _rows([
          'Massage 2h 1,200.00',
          'Herbal ball 350.00',
          'Water 89.50',
          'Towel 60.50',
          'Total 1,700.00',
          'Cash 2,000.00',
          'Change 300.00',
        ]),
      );
      expect(r, isNotNull);
      expect(r!.kind, BillKind.itemsOnly);
      expect(r.total, closeTo(1700.00, 1e-9));
      expect(r.subtotal!, closeTo(1700.00, 1e-9));
      expect(r.itemCount, 4);
    });
  });

  group('Receipts that do not add up give null (rule 5)', () {
    test('Item 60.00 / Item 25.00 / Total 95.00 gives null', () {
      expect(
        checkBill(_rows(['Item 60.00', 'Item 25.00', 'Total 95.00'])),
        isNull,
      );
    });

    test('non-adding receipt with cash and change after gives null', () {
      expect(
        checkBill(
          _rows([
            'Item 60.00',
            'Item 25.00',
            'Total 95.00',
            'Cash 100.00',
            'Change 5.00',
          ]),
        ),
        isNull,
      );
    });

    test('a lone amount with no repeat gives null', () {
      expect(checkBill(_rows(['Total 85.00'])), isNull);
    });

    test('random text without amounts gives null', () {
      expect(
        checkBill(
          _rows(['Welcome to Bangkok', 'Have a nice day', 'Thank you']),
        ),
        isNull,
      );
    });

    test('USD amounts that add up (20.00 + 5.00 = 25.00 USD) give null', () {
      expect(
        checkBill(
          _bill([
            ('Item', '20.00 USD'),
            ('Item', '5.00 USD'),
            ('Total', '25.00 USD'),
          ]),
        ),
        isNull,
      );
    });
  });
}
