import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/bill_check.dart';
import 'package:money_navigation/rules/ocr_layout.dart';

// Printed lines of real Thai receipts found online, one block per receipt:
// `### ID title | type | source URL | exact|partial | adds up: yes|no`
// followed by the printed lines. flutter test runs from app/.
const String _dir = 'test/rules/fixtures/real_receipts';
const List<String> _files = ['early.txt', 'shops.txt', 'food.txt', 'travel.txt'];

class _Receipt {
  _Receipt(this.id, this.header, this.addsUp, this.lines);

  final String id;
  final String header;
  final bool addsUp;
  final List<String> lines;
}

final RegExp _addsUp = RegExp(r'adds up:\s*(yes|no)');

List<_Receipt> _loadReceipts() {
  final out = <_Receipt>[];
  for (final name in _files) {
    _Receipt? current;
    for (final raw in File('$_dir/$name').readAsLinesSync()) {
      final line = raw.trim();
      if (raw.startsWith('### ')) {
        final header = raw.substring(4).trim();
        final verdict = _addsUp.firstMatch(header)?.group(1);
        if (verdict == null) {
          throw StateError('Block without "adds up" in $name: $header');
        }
        current = _Receipt(
          header.split(' ').first,
          header,
          verdict == 'yes',
          [],
        );
        out.add(current);
      } else if (line.isEmpty) {
        current = null;
      } else if (current != null) {
        current.lines.add(line);
      }
    }
  }
  return out;
}

/// One OCR line per printed line, stacked top to bottom.
List<OcrLine> _ocrLines(List<String> printed) => [
  for (var i = 0; i < printed.length; i++)
    OcrLine(
      text: printed[i],
      left: 0,
      top: i * 40.0,
      right: 20.0 * printed[i].length,
      bottom: i * 40.0 + 30,
    ),
];

// The amount each receipt asks the customer to pay, in THB, read from the
// last printed amount on its payable-total row.
const Map<String, double> _expectedTotal = {
  // early.txt
  '01': 9.00, // Total (1)
  '02': 56.00, // ยอดสุทธิ 3 ชิ้น
  '03': 649.00, // ยอดสุทธิ 24 ชิ้น
  '04a': 1198.50, // Total (24ชิ้น)
  '04b': 839.00, // Total (9ชิ้น)
  '05': 330.00, // Total
  '06': 233.00, // ยอดชำระ
  '07': 435.49, // สุทธิ
  '08': 370.00, // Total
  '09': 165.00, // Eat-In Total (incl Tax)
  '10': 234.00, // TAKE OUT TOTAL WITH VAT
  '11': 1362.00, // คงเหลือจำนวนเงิน
  '12': 670, // Total:
  '13': 1525.00, // รวมสุทธิ
  '14a': 600, // รวมเงิน Total
  '14b': 1215, // รวม TOTAL
  '15': 55.00, // TOTAL
  // shops.txt
  'S01': 44.00, // ยอดสุทธิ 4 ชิ้น
  'S02': 63.00, // ยอดสุทธิ 2 ชิ้น
  'S03': 122.50, // ยอดสุทธิ 6 ชิ้น
  'S04': 258.00, // ยอดสุทธิ 30 ชิ้น
  'S05': 116.00, // ยอดรวม (the coupon is tender, not a discount)
  'S06': 225.00, // Total (8ชิ้น)
  'S07': 10893.00, // รวมเงินสุทธิ
  'S08': 332.00, // TOTAL
  'S09': 3025.00, // TOTAL
  'S10': 79.50, // NET BAHT
  'S11': 1950.50, // ยอดชำระ
  // food.txt
  'F01': 134.00, // Net-TOTAL
  'F02': 2330.46, // Total Due
  'F03': 660, // รวมเงิน TOTAL
  'F04': 908, // รวมเงิน TOTAL
  'F05': 630, // รวมเงิน TOTAL
  'F06': 742.00, // Total:
  'F07': 920.20, // TOTAL
  'F08': 115.00, // Total VATable (unlabeled 115.00 rows above)
  'F09': 1848.00, // Total
  'F10': 2644.50, // ทั้งหมด
  'F11': 154.00, // Subtotal 2 / ฿154.00
  'F12': 464.00, // Total
  'F13': 350.00, // ทั้งหมด
  'F14': 230.00, // ทั้งหมด
  'F15': 369.00, // ทั้งหมด
  // travel.txt
  'T01': 671.00, // Total
  'T02': 105.00, // TOTAL
  'T03': 8586.00, // ยอดรวม
  'T04': 1500, // Total (Thai Baht)
  'T05': 1900, // รวม บาท
};

const double _eps = 0.001;

void main() {
  final receipts = _loadReceipts();
  final byId = {for (final r in receipts) r.id: r};

  BillCheck? check(String id) {
    final r = byId[id];
    if (r == null) throw StateError('No receipt $id in fixtures');
    return checkBill(_ocrLines(r.lines));
  }

  group('fixtures', () {
    test('every block parsed with a unique id and printed lines', () {
      expect(receipts.length, 51);
      expect(byId.length, receipts.length, reason: 'ids must be unique');
      for (final r in receipts) {
        expect(r.lines, isNotEmpty, reason: r.header);
      }
    });

    test('every receipt that adds up has a hard-coded expected total', () {
      final yes = {for (final r in receipts) if (r.addsUp) r.id};
      expect(_expectedTotal.keys.toSet(), yes);
    });

    test('exactly N1, X01 and X02 are marked as not adding up', () {
      expect(
        {for (final r in receipts) if (!r.addsUp) r.id},
        {'N1', 'X01', 'X02'},
      );
    });
  });

  group('receipts that do not add up are never verified', () {
    for (final r in receipts.where((r) => !r.addsUp)) {
      test('${r.id} -> null', () {
        expect(checkBill(_ocrLines(r.lines)), isNull, reason: r.header);
      });
    }
  });

  group('receipts that add up are verified with the payable total', () {
    for (final r in receipts.where((r) => r.addsUp)) {
      test('${r.id} total ${_expectedTotal[r.id]}', () {
        final bill = checkBill(_ocrLines(r.lines));
        expect(bill, isNotNull, reason: 'not verified: ${r.header}');
        expect(bill!.total, closeTo(_expectedTotal[r.id]!, _eps),
            reason: r.header);
      });
    }
  });

  group('key fields', () {
    test('06 Black Canyon: discount and service charge, VAT inside', () {
      final b = check('06')!;
      expect(b.kind, BillKind.serviceCharge);
      expect(b.total, closeTo(233.00, _eps));
      expect(b.subtotal, closeTo(225.00, _eps));
      expect(b.discount, closeTo(13.00, _eps));
      expect(b.serviceCharge, closeTo(21.00, _eps));
      expect(b.vat, closeTo(15.24, _eps));
      expect(b.vatIncluded, isTrue);
      expect(b.vatAddedOnTop, isFalse);
    });

    test('07 Kumpoon: service charge with VAT added on top (++)', () {
      final b = check('07')!;
      expect(b.kind, BillKind.serviceCharge);
      expect(b.total, closeTo(435.49, _eps));
      expect(b.serviceCharge, closeTo(37.00, _eps));
      expect(b.vat, closeTo(28.49, _eps));
      expect(b.vatAddedOnTop, isTrue);
    });

    test('F07 Sun Sabella: VAT on top of the items', () {
      final b = check('F07')!;
      expect(b.kind, BillKind.vatOnTop);
      expect(b.total, closeTo(920.20, _eps));
      expect(b.vat, closeTo(60.20, _eps));
      expect(b.vatAddedOnTop, isTrue);
    });

    test('F10 Bubble in the Forest: VAT and service inside the prices', () {
      final b = check('F10')!;
      expect(b.kind, BillKind.vatIncluded);
      expect(b.total, closeTo(2644.50, _eps));
      expect(b.serviceCharge, closeTo(224.68, _eps));
      expect(b.serviceAddedOnTop, isFalse);
      expect(b.vatAddedOnTop, isFalse);
    });

    test('S04 7-Eleven delivery: unsigned discounts and coupons', () {
      final b = check('S04')!;
      expect(b.kind, BillKind.itemsOnly);
      expect(b.total, closeTo(258.00, _eps));
      expect(b.discount, closeTo(78.50, _eps));
    });

    test('F02 Ta-Kri: discount, service charge and VAT on top', () {
      final b = check('F02')!;
      expect(b.kind, BillKind.serviceCharge);
      expect(b.total, closeTo(2330.46, _eps));
      expect(b.discount, closeTo(220.00, _eps));
      expect(b.serviceCharge, closeTo(198.00, _eps));
      expect(b.vat, closeTo(152.46, _eps));
      expect(b.vatAddedOnTop, isTrue);
    });

    test('F06 Hops Brewhouse: service charge, VAT on before-tax amount', () {
      final b = check('F06')!;
      expect(b.kind, BillKind.serviceCharge);
      expect(b.total, closeTo(742.00, _eps));
      expect(b.vat, closeTo(48.51, _eps));
      expect(b.beforeVat, closeTo(693.00, _eps));
    });

    test('S05 Lotus\'s: a coupon handed over is tender, not a discount', () {
      final b = check('S05')!;
      expect(b.total, closeTo(116.00, _eps));
      expect(b.discount, isNull);
    });
  });
}
