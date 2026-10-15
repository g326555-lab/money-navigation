import 'package:intl/intl.dart';

/// Money and percent formatting. Amounts read like "4,220 THB".
abstract final class AppFormat {
  /// Joins a number and its unit so they never break across lines.
  static const _unitGap = '\u00A0';

  static String _number(double value, int decimals, String locale) =>
      NumberFormat.decimalPatternDigits(
        locale: locale,
        decimalDigits: decimals,
      ).format(value);

  /// Whole units when the value has no cents, otherwise two decimals.
  static String amount(double value, String currency, {String locale = 'en'}) {
    final whole = (value - value.roundToDouble()).abs() < 0.005;
    return '${_number(value, whole ? 0 : 2, locale)}$_unitGap$currency';
  }

  /// Rounded to whole units, for estimates shown with "about".
  static String roundedAmount(
    double value,
    String currency, {
    String locale = 'en',
  }) => '${_number(value.roundToDouble(), 0, locale)}$_unitGap$currency';

  /// Number only, rounded to whole units, for the hero figure.
  static String roundedNumber(double value, {String locale = 'en'}) =>
      _number(value.roundToDouble(), 0, locale);

  static String cents(double value, String currency, {String locale = 'en'}) =>
      '${_number(value, 2, locale)}$_unitGap$currency';

  static String rate(double value, {String locale = 'en'}) =>
      _number(value, 2, locale);

  /// Whole percent with separators, for large estimates: "1,036%".
  static String percentWhole(double value, {String locale = 'en'}) =>
      '${_number(value.roundToDouble(), 0, locale)}%';

  /// One decimal, for estimates shown with "about": "1.5%".
  static String roundedPercent(double value, {String locale = 'en'}) =>
      '${_number(value, 1, locale)}%';

  static String percent(double value, {String locale = 'en'}) =>
      '${_number(value, 2, locale)}%';

  /// An estimate in [currency], rounded to that currency's usual minor units
  /// (whole won and yen, cents for dollars and euros).
  static String estimate(
    double value,
    String currency, {
    String locale = 'en',
  }) {
    final digits =
        NumberFormat.simpleCurrency(name: currency).decimalDigits ?? 2;
    return '${_number(value, digits, locale)}$_unitGap$currency';
  }

  /// A rate as stated, never rounded away: 4.6935, 35.565, 33.58. At least
  /// two decimals, at most four. For rates printed on a board, a fixed demo
  /// rate or a mid rate, where the reader may check every digit.
  static String preciseRate(double value, {String locale = 'en'}) =>
      (NumberFormat.decimalPattern(locale)
            ..minimumFractionDigits = 2
            ..maximumFractionDigits = 4)
          .format(value);

  /// A rate with enough significant digits to be useful, e.g. 41.62 or 0.0298.
  static String rateValue(double value, {String locale = 'en'}) {
    final digits = value >= 10 ? 2 : (value >= 1 ? 3 : 4);
    return _number(value, digits, locale);
  }
}
