import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/atm_conversion.dart';
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
  group('declineButtonLabel: real ML Kit iOS capture', () {
    test('reads the two-line button "Accept without currency conversion"', () {
      expect(
        declineButtonLabel(atmRealIosLines),
        'Accept without currency conversion',
      );
    });

    test('ignores the "without conversion" column header', () {
      expect(declineButtonLabel(atmRealIosLines), isNot(contains('Withdraw')));
    });

    test('does not depend on the input order of the lines', () {
      expect(
        declineButtonLabel(atmRealIosLines.reversed.toList()),
        'Accept without currency conversion',
      );
    });
  });

  group('declineButtonLabel: synthetic screens', () {
    test('empty list gives null', () {
      expect(declineButtonLabel(const []), isNull);
    });

    test('a screen without a "without" button gives null', () {
      expect(
        declineButtonLabel([
          line('Decline conversion', 400, 900, 800, 950),
          line('Accept conversion', 1300, 900, 1700, 950),
        ]),
        isNull,
      );
    });

    test('a single-line button with nothing below gives its text', () {
      expect(
        declineButtonLabel([
          line('Accept without conversion', 400, 900, 900, 950),
        ]),
        'Accept without conversion',
      );
    });

    test('a header with "without" but no action verb gives null', () {
      expect(
        declineButtonLabel([
          line('Withdraw', 700, 150, 900, 190),
          line('without conversion', 700, 200, 1100, 240),
        ]),
        isNull,
      );
    });

    test('a line that holds a number is not a button label', () {
      expect(
        declineButtonLabel([line('Pay without 4.220 THB', 400, 900, 900, 950)]),
        isNull,
      );
    });

    test('the verb is matched without regard to case', () {
      expect(
        declineButtonLabel([
          line('CONTINUE WITHOUT CONVERSION', 0, 0, 500, 50),
        ]),
        'CONTINUE WITHOUT CONVERSION',
      );
    });

    test('a line in another column is not appended', () {
      expect(
        declineButtonLabel([
          line('Accept without', 400, 900, 800, 950),
          line('currency conversion', 1200, 950, 1700, 1000),
        ]),
        'Accept without',
      );
    });

    test('a line too far below is not appended', () {
      // Height 50, so the limit is 75 px below the bottom (950 + 75 = 1025).
      expect(
        declineButtonLabel([
          line('Accept without', 400, 900, 800, 950),
          line('Cancel', 400, 1100, 600, 1150),
        ]),
        'Accept without',
      );
    });

    test('whitespace is collapsed to single spaces', () {
      expect(
        declineButtonLabel([
          line('Accept   without ', 400, 900, 800, 950),
          line('  currency  conversion', 400, 955, 900, 1005),
        ]),
        'Accept without currency conversion',
      );
    });
  });
}
