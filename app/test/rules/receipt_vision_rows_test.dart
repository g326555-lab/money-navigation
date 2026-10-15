import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/bill_check.dart';
import 'package:money_navigation/rules/ocr_layout.dart';

// Row texts exactly as Google Vision returned them for real receipt photos.
// Vision merges and splits printed lines differently from the paper, so these
// protect the role reader against the shapes a camera actually produces.

/// One OCR line per Vision row, stacked top to bottom.
List<OcrLine> _rows(List<String> rows) => [
  for (var i = 0; i < rows.length; i++)
    OcrLine(
      text: rows[i],
      left: 0,
      top: i * 40.0,
      right: 20.0 * rows[i].length,
      bottom: i * 40.0 + 30,
    ),
];

const List<String> _taKri = [
  '1 Phak Thod 290.00 T1',
  '1 Satay Gai 270.00 T1',
  'Outlet 1 Gaeng Karee Goong 420.00 T1',
  '1 Kra Prow Moo 320.00 T1',
  '1 Matua S.BCF. 900.00 T1 krai',
  '1 AP Member Benefit 10 -220.00',
  'm1 each Bar',
  '10.00 %',
  'Guest N Food',
  '1300.00',
  'Wine 900.00',
  'Room N',
  'Discount -220.00',
  '10% SVC 198.00',
  '7% Vat 152.46',
  'Scoring: Total Due 2330.46 High',
  '6 10',
];

const List<String> _sunSabella = [
  'Bill# 012861 121021-1-',
  '04/02/2024 Pax 1 Total',
  'Qty Description Spicy Thai Salad w/Grill 220.00 +',
  '1 220.00 +',
  '1 D/F Shrimps Cake 50.00 +',
  '1 Soda 180.00 +',
  '1 TN Hot Coffee (Pot) 190.00 +',
  '1 Margarita',
  '860.00',
  'Subtotal',
  'Service 10% 0.00',
  'Tax 7% 60.20',
  'TOTAL 920.20',
];

const List<String> _happyHerbs = [
  'Order: T-02',
  'C: 50.00',
  '1 x 50.00',
  'Tomato Salad 50.00',
  '1 x 50.00',
  'Soda 20.00',
  '1 x 20.00',
  'Margarita 199.00',
  '1 x 199.00',
  'Daiquiri(Rum) 145.00',
  '1 x 145.00',
  'Margarita 199.00',
  '1 x 199.00',
  'December Promotions -199.00',
  'Total 464.00',
  'Cash 464.00',
];

const List<String> _bootsSriracha = [
  'S&G HAPPY GLAMPER T 600.00',
  'S&G HAPPY GLAMPER T 600.00',
  'PROMOTION DISC. -600.00',
  'S&G HAPPY GLAMPER T 600.00',
  'S&G SUGAR CRUSH SC T 455.00',
  'PROMOTION DISC. -455.00',
  'S&G THE RIGHT BUTT T 480.00',
  'PROMOTION DISC. -25.00',
  'S&G THE RIGHT BUTT T 480.00',
  'PROMOTION DISC. -455.00',
  'S&G BREAKFAST SCRU T 455.00',
  'S&G PINK EDT T 890.00',
  'PROMOTION DISC. -600.00',
  'S&G PINK EDT T 890.00',
  'PROMOTION DISC. -290.00',
  'TOTAL 3.025.00',
  'SALE VISA-TMB 3.025.00',
  'CHANGE 0.00',
  'VATABLE 2.827.10',
  'VAT 7% 197.90',
  'TOTAL QTY 9',
];

const List<String> _sevenEleven = [
  '1 แซนวิชได้กรอก 29.00',
  '2 Hเลย์ร็อครสบาร์บีคิว @45.00 90.00',
  '1 ภารกิจช้อปหน้าร้าน O.OON',
  '1 สิทธิ์แลกซื้อสุดคุ้มAMB 0.OON',
  'ยอด ทร 3 ชิ้น 119.00',
  'ทรูมันนีวอดเ ท 119.00',
];

void main() {
  group('Vision rows of real receipt photos verify to the printed total', () {
    test('Ta-Kri: a percent alone on its row is not an amount', () {
      // 290 + 270 + 420 + 320 + 900 = 2200, -220 = 1980,
      // +198 service = 2178, +152.46 VAT = 2330.46.
      final bill = checkBill(_rows(_taKri));
      expect(bill, isNotNull);
      expect(bill!.kind, BillKind.serviceCharge);
      expect(bill.total, closeTo(2330.46, 0.001));
      expect(bill.serviceCharge, closeTo(198.00, 0.001));
      expect(bill.vat, closeTo(152.46, 0.001));
      expect(bill.vatAddedOnTop, isTrue);
    });

    test('Sun Sabella: "Qty" header merged into the first item row', () {
      // 220 + 220 + 50 + 180 + 190 = 860, +60.20 VAT = 920.20.
      final bill = checkBill(_rows(_sunSabella));
      expect(bill, isNotNull);
      expect(bill!.kind, BillKind.vatOnTop);
      expect(bill.total, closeTo(920.20, 0.001));
      expect(bill.vat, closeTo(60.20, 0.001));
    });

    test('Happy Herbs: standalone "1 x 50.00" unit rows are not items', () {
      // 50 + 50 + 20 + 199 + 145 + 199 - 199 = 464.
      final bill = checkBill(_rows(_happyHerbs));
      expect(bill, isNotNull);
      expect(bill!.kind, BillKind.itemsOnly);
      expect(bill.total, closeTo(464.00, 0.001));
    });

    test('Boots Sriracha: dot thousands "3.025.00" read as 3025', () {
      // Items 3x600 + 2x455 + 2x480 + 2x890 = 5450, discounts 2425,
      // 5450 - 2425 = 3025 = 2827.10 + 197.90.
      final bill = checkBill(_rows(_bootsSriracha));
      expect(bill, isNotNull);
      expect(bill!.kind, BillKind.vatIncluded);
      expect(bill.total, closeTo(3025.00, 0.001));
      expect(bill.vat, closeTo(197.90, 0.001));
      expect(bill.vatIncluded, isTrue);
    });

    test('7-Eleven: free "O.OON" rows do not break the 119 total', () {
      // 29 + 90 + 0 + 0 = 119.
      final bill = checkBill(_rows(_sevenEleven));
      expect(bill, isNotNull);
      expect(bill!.total, closeTo(119.00, 0.001));
    });
  });

  group('Vision rows that do not add up return null', () {
    test('handwritten bill where Vision read 150 as 50', () {
      final bill = checkBill(
        _rows(const [
          'What mne 1.50 300',
          'Sis 60 60',
          'Tom you 150 50',
          'Fried Roasted Chili 150 150',
          'รวมเงิน TOTAL 660',
        ]),
      );
      expect(bill, isNull);
    });

    test('collage of three receipts interleaved row by row', () {
      final collage = <String>[];
      final sources = [_taKri, _sunSabella, _happyHerbs];
      final longest = sources
          .map((s) => s.length)
          .reduce((a, b) => a > b ? a : b);
      for (var i = 0; i < longest; i++) {
        for (final s in sources) {
          if (i < s.length) collage.add(s[i]);
        }
      }
      expect(checkBill(_rows(collage)), isNull);
    });
  });
}
