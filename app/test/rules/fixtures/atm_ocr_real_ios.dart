// Real on-device OCR of demo scene 1 (ATM conversion screen).
//
// Source: real ML Kit iOS simulator capture (latin recognizer) of
// prints/demo-prints-A4.pdf page 1 rendered at 200 dpi, captured 2026-10-15.
// Copied verbatim from the probe log; do not tidy the text.
//
// Quirks visible in this capture:
// - "4. 000 THB": a space after the thousands dot;
// - "1 USD" and "30.86 THB" are separate lines and there is no "=" sign;
// - the label reads "Exchange rate markup" (no hyphen);
// - the raw text is column-wise and mixed, so values cannot be paired with
//   labels by text order;
// - the photo is slightly tilted: a label's box sits up to about 26 px lower
//   than its values on a line about 40 px high.
//
// Boxes are left, top, right, bottom in image pixels.

import 'package:money_navigation/rules/ocr_layout.dart';

/// Every line ML Kit returned, in the order it returned them.
const List<OcrLine> atmRealIosLines = [
  OcrLine(text: 'Withdraw', left: 708, top: 157, right: 903, bottom: 196),
  OcrLine(
    text: 'without conversion',
    left: 715,
    top: 205,
    right: 1107,
    bottom: 243,
  ),
  OcrLine(text: '4. 000 THB', left: 727, top: 273, right: 1053, bottom: 317),
  OcrLine(text: '220 THB', left: 807, top: 387, right: 1051, bottom: 428),
  OcrLine(text: '1 USD', left: 962, top: 497, right: 1129, bottom: 543),
  OcrLine(text: 'Withdraw', left: 1326, top: 163, right: 1518, bottom: 199),
  OcrLine(
    text: 'with conversion',
    left: 1328,
    top: 206,
    right: 1640,
    bottom: 248,
  ),
  OcrLine(text: '137.17 USD', left: 1401, top: 275, right: 1743, bottom: 316),
  OcrLine(text: '7.54 USD', left: 1470, top: 387, right: 1740, bottom: 427),
  OcrLine(text: '30.86 THB', left: 1431, top: 493, right: 1736, bottom: 539),
  OcrLine(text: '5.50 %', left: 1536, top: 605, right: 1734, bottom: 645),
  OcrLine(text: '144.71 USD', left: 1395, top: 707, right: 1733, bottom: 755),
  OcrLine(
    text: 'Withdrawal amount',
    left: 301,
    top: 284,
    right: 684,
    bottom: 315,
  ),
  OcrLine(text: 'Access fee', left: 304, top: 395, right: 522, bottom: 429),
  OcrLine(text: 'Exchange rate', left: 311, top: 512, right: 591, bottom: 550),
  OcrLine(
    text: 'Exchange rate markup',
    left: 319,
    top: 625,
    right: 772,
    bottom: 664,
  ),
  OcrLine(text: 'Amount charged', left: 322, top: 735, right: 645, bottom: 779),
  OcrLine(text: '4.220 THB', left: 742, top: 718, right: 1059, bottom: 761),
  OcrLine(
    text: 'Accept without',
    left: 417,
    top: 969,
    right: 791,
    bottom: 1024,
  ),
  OcrLine(
    text: 'currency conversion',
    left: 417,
    top: 1016,
    right: 906,
    bottom: 1077,
  ),
  OcrLine(text: 'Cancel', left: 425, top: 1174, right: 585, bottom: 1218),
  OcrLine(
    text: 'Photo: ASEAN NOW forum (aseannow. com)',
    left: 65,
    top: 1317,
    right: 492,
    bottom: 1342,
  ),
  OcrLine(text: 'Accept with', left: 1413, top: 942, right: 1691, bottom: 998),
  OcrLine(
    text: 'currency conversion',
    left: 1223,
    top: 996,
    right: 1698,
    bottom: 1065,
  ),
];

/// `RecognizedText.text` from the same capture, verbatim.
const String atmRealIosRawText = '''
Withdraw
without conversion
4. 000 THB
220 THB
1 USD
Withdraw
with conversion
137.17 USD
7.54 USD
30.86 THB
5.50 %
144.71 USD
Withdrawal amount
Access fee
Exchange rate
Exchange rate markup
Amount charged
4.220 THB
Accept without
currency conversion
Cancel
Photo: ASEAN NOW forum (aseannow. com)
Accept with
currency conversion
''';
