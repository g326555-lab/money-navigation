import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/amount_parser.dart';

void main() {
  group('parseAmount: comma thousands separator', () {
    test('"4,000" is 4000', () => expect(parseAmount('4,000'), 4000));
    test('"4,220.00" is 4220', () => expect(parseAmount('4,220.00'), 4220));
    test(
      '"12,851.82" is 12851.82',
      () => expect(parseAmount('12,851.82'), closeTo(12851.82, 1e-9)),
    );
  });

  group('parseAmount: dot read as thousands separator (ML Kit ATM quirk)', () {
    test('"4.000" is 4000, not 4', () => expect(parseAmount('4.000'), 4000));
    test('"4.220" is 4220, not 4.22', () => expect(parseAmount('4.220'), 4220));
    test(
      '"4.000 THB" with currency suffix is 4000',
      () => expect(parseAmount('4.000 THB'), 4000),
    );
    test(
      '"4.220 THB" with currency suffix is 4220',
      () => expect(parseAmount('4.220 THB'), 4220),
    );
  });

  group('parseAmount: space after thousands dot (real ML Kit iOS capture)', () {
    test('"4. 000 THB" is 4000', () => expect(parseAmount('4. 000 THB'), 4000));
    test('"4. 000" is 4000', () => expect(parseAmount('4. 000'), 4000));
    test('"4. 220" is 4220', () => expect(parseAmount('4. 220'), 4220));
    test('"4.00" still is 4, not 400', () => expect(parseAmount('4.00'), 4));
  });

  group('parseAmount: space after comma (Japanese terminal quirk)', () {
    test(
      '"12, 851.82" is 12851.82',
      () => expect(parseAmount('12, 851.82'), closeTo(12851.82, 1e-9)),
    );
    test('"58, 000" is 58000', () => expect(parseAmount('58, 000'), 58000));
  });

  group('parseAmount: ordinary decimals stay decimals', () {
    test(
      '"30.86" is 30.86',
      () => expect(parseAmount('30.86'), closeTo(30.86, 1e-9)),
    );
    test(
      '"144.71" is 144.71',
      () => expect(parseAmount('144.71'), closeTo(144.71, 1e-9)),
    );
    test(
      '"137.17 USD" is 137.17',
      () => expect(parseAmount('137.17 USD'), closeTo(137.17, 1e-9)),
    );
    test('"220" is 220', () => expect(parseAmount('220'), 220));
    test(
      '"4.00" (two decimals) is 4, not 400',
      () => expect(parseAmount('4.00'), 4),
    );
    test(
      'surrounding whitespace is ignored',
      () => expect(parseAmount('  30.86  '), closeTo(30.86, 1e-9)),
    );
  });

  group('parseAmount: percent', () {
    test(
      '"5.50%" is 5.5',
      () => expect(parseAmount('5.50%'), closeTo(5.5, 1e-9)),
    );
    test(
      '"5.50 %" is 5.5',
      () => expect(parseAmount('5.50 %'), closeTo(5.5, 1e-9)),
    );
  });

  group('parseAmount: no guessing, null for unreadable input', () {
    for (final raw in ['', '   ', 'abc', 'THB', '%', '--', '.', ',']) {
      test('"$raw" is null', () => expect(parseAmount(raw), isNull));
    }
  });
}
