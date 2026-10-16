import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/bill_check.dart';
import 'package:money_navigation/rules/ocr_layout.dart';
import 'package:money_navigation/rules/receipt_roles.dart';

/// Cloud Vision answers for two photos of one Starbucks Thailand receipt
/// (16 Oct 2026): "Sub Total 150.00", "Total Amount 150.00",
/// "9.81 VAT TTL 150.00", "Net TTL. 140.19". The VAT figure is printed
/// before its label; photo a also reads "1.50.00" for the total.
void main() {
  for (final name in ['starbucks_a', 'starbucks_b']) {
    test('$name: 150.00 with VAT 9.81 inside', () {
      final vision = jsonDecode(
        File('test/rules/fixtures/vision/$name.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final check = checkBillFromVision(vision)!;
      expect(check.total, 150);
      expect(check.vat, 9.81);
      expect(check.beforeVat, closeTo(140.19, 0.001));
      expect(check.kind, BillKind.vatIncluded);
    });
  }

  test('a QR payment slip prints only "Total ... THB160.00"', () {
    final vision = jsonDecode(
      File('test/rules/fixtures/vision/receipt_c.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    // Nothing to check it against: no verified bill...
    expect(checkBillFromVision(vision), isNull);
    final quads = [
      for (final l in vision['lines'] as List)
        OcrQuad(
          text: l['text'] as String,
          corners: [
            for (final c in l['corners'] as List)
              ((c[0] as num).toDouble(), (c[1] as num).toDouble()),
          ],
        ),
    ];
    // ...but the printed total is read for an unverified record.
    final rows = rowsFromLines(straightenLines(quads)).split('\n');
    expect(printedTotalOnly(rows), 160);
  });

  test('no total row, no total', () {
    expect(printedTotalOnly(['Latte 60.00', 'THB60.00']), isNull);
    expect(printedTotalOnly(['Total', 'THB1,250.50']), 1250.5);
    expect(printedTotalOnly(['Total 89.00']), 89);
  });
}
