// OCR fixtures for demo scene 1 (ATM conversion screen).
//
// Source: no raw ML Kit output of the ATM photo was saved during preparation,
// so these strings are reconstructed from the printed prop
// (prints/demo-prints-A4.pdf, page 1) and the OCR quirks recorded in
// docs/prep-notes.md section 3: ML Kit reads the thousands separator as a dot
// ("4.000 THB", "4.220 THB"), and labels and values come back as separate
// lines. Replace or extend with a real capture once one is recorded on device.
//
// The printed screen also shows the "with conversion" column
// (137.17 USD, 7.54 USD). A parser must not confuse those with the
// charged amount (144.71 USD).

/// Block order: ML Kit groups the screen into column blocks, so all labels
/// come first, then the THB column, then the USD column. Thousands dot quirk.
const String atmOcrBlockOrder = '''
Withdraw
without conversion
Withdraw
with conversion
Withdrawal amount
Access fee
Exchange rate
Exchange rate mark-up
Amount charged
4.000 THB
220 THB
4.220 THB
137.17 USD
7.54 USD
1 USD
=
30.86 THB
5.50 %
144.71 USD
Accept without
currency conversion
Accept with
currency conversion
Cancel
''';

/// Row order: each label shares a line with its values. Comma separators.
const String atmOcrRowOrder = '''
Withdraw without conversion Withdraw with conversion
Withdrawal amount 4,000 THB 137.17 USD
Access fee 220 THB 7.54 USD
Exchange rate 1 USD = 30.86 THB
Exchange rate mark-up 5.50 %
Amount charged 4,220 THB 144.71 USD
Accept without currency conversion
Accept with currency conversion
Cancel
''';

/// A second, made-up screen with different numbers, so a parser or verdict
/// that only works for the demo values fails.
/// 2,220 / 32.50 = 68.3077 fair USD; 71.04 charged; extra 2.7323 USD.
const String atmOcrOtherNumbers = '''
Withdrawal amount 2.000 THB 61.54 USD
Access fee 220 THB 6.77 USD
Exchange rate 1 USD = 32.50 THB
Exchange rate mark-up 4.00 %
Amount charged 2.220 THB 71.04 USD
Accept without currency conversion
Accept with currency conversion
''';

/// Same layout as the demo, but the screen states no mark-up line.
const String atmOcrNoMarkup = '''
Withdrawal amount 4.000 THB 137.17 USD
Access fee 220 THB 7.54 USD
Exchange rate 1 USD = 30.86 THB
Amount charged 4.220 THB 144.71 USD
''';

/// The "Amount charged" row was not read (glare, blur).
const String atmOcrMissingCharged = '''
Withdrawal amount 4.000 THB 137.17 USD
Access fee 220 THB 7.54 USD
Exchange rate 1 USD = 30.86 THB
Exchange rate mark-up 5.50 %
''';

/// The exchange rate row was not read.
const String atmOcrMissingRate = '''
Withdrawal amount 4.000 THB 137.17 USD
Access fee 220 THB 7.54 USD
Exchange rate mark-up 5.50 %
Amount charged 4.220 THB 144.71 USD
''';

/// Charged THB was read but the USD charged value was not.
const String atmOcrMissingChargedUsd = '''
Withdrawal amount 4.000 THB 137.17 USD
Access fee 220 THB 7.54 USD
Exchange rate 1 USD = 30.86 THB
Exchange rate mark-up 5.50 %
Amount charged 4.220 THB
''';

/// The rate reads as zero (misread digits). Must not be accepted.
const String atmOcrZeroRate = '''
Withdrawal amount 4.000 THB 137.17 USD
Access fee 220 THB 7.54 USD
Exchange rate 1 USD = 0.00 THB
Exchange rate mark-up 5.50 %
Amount charged 4.220 THB 144.71 USD
''';

/// A photo of something that is not an ATM conversion screen.
const String ocrNotAnAtm = '''
7-Eleven
Thank you
Please come again
''';
