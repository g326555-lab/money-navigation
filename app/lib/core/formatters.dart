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

  static String percent(double value, {String locale = 'en'}) =>
      '${_number(value, 2, locale)}%';
}
