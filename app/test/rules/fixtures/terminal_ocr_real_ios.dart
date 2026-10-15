// Real on-device OCR of demo scene 3 (Japanese card terminal, DCC choice).
//
// Source: real ML Kit iOS simulator capture (latin recognizer) of
// prints/demo-prints-A4.pdf page 2 rendered at 200 dpi with pdftoppm,
// captured 2026-10-15. Copied verbatim from the probe log, in the order ML
// Kit returned the lines; do not tidy the text.
//
// Quirks visible in this capture:
// - "12, 851.82" and "58, 000": a space after the thousands comma;
// - "F2:JPY" and "58, 000" are separate lines (same visual row), while
//   "F1:THB 12, 851.82" is one line;
// - keypad labels "F1", "F2" and "F1 OR F2" also appear further down and
//   carry no amount;
// - keypad letters and the caption produce junk lines ("Qz", "JE",
//   "ngusenánasiuiciesn.tsjuvesga", "DDD7L372").
//
// Boxes are left, top, right, bottom in image pixels.

import 'package:money_navigation/rules/ocr_layout.dart';

/// Every line ML Kit returned, in the order it returned them.
const List<OcrLine> terminalRealIosLines = [
  OcrLine(
    text: 'Select Currency',
    left: 645,
    top: 393,
    right: 1048,
    bottom: 457,
  ),
  OcrLine(
    text: 'F1:THB 12, 851.82',
    left: 643,
    top: 455,
    right: 1077,
    bottom: 529,
  ),
  OcrLine(text: 'F2:JPY', left: 642, top: 519, right: 799, bottom: 580),
  OcrLine(text: '58, 000', left: 919, top: 525, right: 1072, bottom: 597),
  OcrLine(text: 'TEC', left: 779, top: 718, right: 898, bottom: 764),
  OcrLine(text: 'ABC', left: 883, top: 847, right: 929, bottom: 870),
  OcrLine(text: '2', left: 880, top: 864, right: 925, bottom: 921),
  OcrLine(text: '5', left: 882, top: 988, right: 919, bottom: 1058),
  OcrLine(text: '8', left: 874, top: 1154, right: 911, bottom: 1201),
  OcrLine(text: 'TUV', left: 872, top: 1129, right: 914, bottom: 1148),
  OcrLine(text: 'Qz', left: 750, top: 844, right: 778, bottom: 864),
  OcrLine(text: 'GHI', left: 738, top: 982, right: 778, bottom: 1001),
  OcrLine(text: 'MNO', left: 1018, top: 994, right: 1067, bottom: 1012),
  OcrLine(text: '6', left: 1022, top: 1022, right: 1057, bottom: 1064),
  OcrLine(text: 'WXY', left: 1012, top: 1136, right: 1061, bottom: 1155),
  OcrLine(text: '9', left: 1016, top: 1161, right: 1052, bottom: 1207),
  OcrLine(text: 'ENTER', left: 1008, top: 1290, right: 1070, bottom: 1307),
  OcrLine(text: 'PRS', left: 733, top: 1123, right: 773, bottom: 1140),
  OcrLine(text: '7', left: 737, top: 1149, right: 768, bottom: 1193),
  OcrLine(text: 'CLEAR', left: 705, top: 1274, right: 765, bottom: 1291),
  OcrLine(text: 'JE', left: 699, top: 1298, right: 772, bottom: 1336),
  OcrLine(text: 'F1', left: 578, top: 839, right: 637, bottom: 868),
  OcrLine(text: 'F2', left: 573, top: 943, right: 636, bottom: 973),
  OcrLine(text: 'F1 OR F2', left: 503, top: 1030, right: 649, bottom: 1064),
  OcrLine(text: 'CANCEL', left: 539, top: 1267, right: 614, bottom: 1286),
  OcrLine(
    text: 'ngusenánasiuiciesn.tsjuvesga',
    left: 501,
    top: 1605,
    right: 1067,
    bottom: 1657,
  ),
  OcrLine(text: 'VISA', left: 505, top: 1730, right: 710, bottom: 1817),
  OcrLine(
    text: 'You can choose',
    left: 565,
    top: 1888,
    right: 979,
    bottom: 1952,
  ),
  OcrLine(
    text: 'your payment currency',
    left: 476,
    top: 1938,
    right: 1066,
    bottom: 2013,
  ),
  OcrLine(
    text: 'Dynamic Currency Conversi',
    left: 456,
    top: 2034,
    right: 1013,
    bottom: 2099,
  ),
  OcrLine(
    text: 'Example image for an app demo. Amounts edited with Al. Original photo: ETtoday.',
    left: 49,
    top: 2159,
    right: 871,
    bottom: 2175,
  ),
  OcrLine(text: 'DDD7L372', left: 1095, top: 1723, right: 1589, bottom: 1833),
];
