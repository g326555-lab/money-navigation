/// Parses money text as read by on-device OCR.
///
/// Handles the quirks recorded in docs/prep-notes.md:
/// - comma thousands separators, with or without a space after the comma
///   ("12,851.82", "12, 851.82");
/// - a dot used as the thousands separator, with or without a space after
///   it ("4.000 THB" and "4. 000 THB" both mean 4,000);
/// - a trailing currency code or percent sign ("144.71 USD", "5.50 %").
///
/// Returns null when the text is not a number. It never guesses.
double? parseAmount(String raw) {
  var text = raw.trim();
  text = text.replaceFirst(_trailingUnit, '').trim();
  text = text.replaceAll(_commaSpace, ',');
  text = text.replaceAll(_dotSpace, '.');
  if (!_numberShape.hasMatch(text)) return null;

  if (text.contains(',')) {
    // Commas are thousands separators; a dot, if any, is the decimal point.
    return double.tryParse(text.replaceAll(',', ''));
  }

  final dots = '.'.allMatches(text).length;
  if (dots > 1 || _dotThousands.hasMatch(text)) {
    // "4.000" or "1.234.567": the dot groups thousands.
    return double.tryParse(text.replaceAll('.', ''));
  }
  return double.tryParse(text);
}

/// Pattern for one amount inside longer OCR text, before any unit.
/// Matches grouped forms ("4,220.00", "4.220", "4. 000", "12, 851.82") and plain
/// forms ("220", "30.86").
const amountPattern = r'\d{1,3}(?:[.,] ?\d{3})+(?:\.\d{1,2})?|\d+(?:\.\d+)?';

final _trailingUnit = RegExp(r'\s*(?:[A-Za-z]{3}|%)$');
final _commaSpace = RegExp(r',\s+');
final _dotSpace = RegExp(r'\.\s+(?=\d{3}(?!\d))');
final _numberShape = RegExp(r'^\d[\d.,]*$');
final _dotThousands = RegExp(r'^\d{1,3}\.\d{3}$');
