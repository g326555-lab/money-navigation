import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/atm_conversion.dart';
import 'package:money_navigation/rules/ocr_layout.dart';

import 'fixtures/atm_ocr_real_ios.dart';

// Image center of the real capture: prints/demo-prints-A4.pdf page 1 at
// 200 dpi is 1654 x 2339 px (see fixtures/atm_ocr_real_ios.dart).
const double _cx = 1654 / 2;
const double _cy = 2339 / 2;

double _rad(double degrees) => degrees * math.pi / 180;

/// Corners of an axis-aligned box in ML Kit order:
/// top-left, top-right, bottom-right, bottom-left.
List<(double, double)> _corners(OcrLine l) => [
  (l.left, l.top),
  (l.right, l.top),
  (l.right, l.bottom),
  (l.left, l.bottom),
];

/// Rotates a point by [degrees] about (cx, cy) in image coordinates
/// (y grows downwards), the same convention as atan2(dy, dx) of a top edge.
(double, double) _rotate(
  (double, double) p,
  double degrees, {
  double cx = _cx,
  double cy = _cy,
}) {
  final t = _rad(degrees);
  final dx = p.$1 - cx;
  final dy = p.$2 - cy;
  return (
    cx + dx * math.cos(t) - dy * math.sin(t),
    cy + dx * math.sin(t) + dy * math.cos(t),
  );
}

OcrQuad _rotatedQuad(OcrLine l, double degrees, {double? cx, double? cy}) =>
    OcrQuad(
      text: l.text,
      corners: _corners(l)
          .map((p) => _rotate(p, degrees, cx: cx ?? _cx, cy: cy ?? _cy))
          .toList(),
    );

List<OcrQuad> _rotatedFixture(double degrees) =>
    atmRealIosLines.map((l) => _rotatedQuad(l, degrees)).toList();

/// What happens today without straightening: the tilted quad is reduced to
/// its axis-aligned bounding box.
OcrLine _naiveBox(OcrQuad q) {
  final xs = q.corners.map((p) => p.$1);
  final ys = q.corners.map((p) => p.$2);
  return OcrLine(
    text: q.text,
    left: xs.reduce(math.min),
    top: ys.reduce(math.min),
    right: xs.reduce(math.max),
    bottom: ys.reduce(math.max),
  );
}

bool _isDemoReading(AtmScreenReading? r) =>
    r != null &&
    (r.withdrawalThb - 4000).abs() < 1e-9 &&
    (r.accessFeeThb - 220).abs() < 1e-9 &&
    (r.thbPerUsd - 30.86).abs() < 1e-9 &&
    r.markupPercent != null &&
    (r.markupPercent! - 5.50).abs() < 1e-9 &&
    (r.chargedThb - 4220).abs() < 1e-9 &&
    (r.chargedUsd - 144.71).abs() < 1e-9;

void _expectDemoReading(AtmScreenReading? r) {
  expect(r, isNotNull);
  expect(r!.withdrawalThb, closeTo(4000, 1e-9));
  expect(r.accessFeeThb, closeTo(220, 1e-9));
  expect(r.thbPerUsd, closeTo(30.86, 1e-9));
  expect(r.markupPercent, closeTo(5.50, 1e-9));
  expect(r.chargedThb, closeTo(4220, 1e-9));
  expect(r.chargedUsd, closeTo(144.71, 1e-9));
}

/// Straightening rotates about the origin, so boxes may be shifted as a whole,
/// but each box must keep the original width and height (a box still tilted
/// would come out larger).
void _expectSameSize(OcrLine actual, OcrLine original) {
  expect(actual.text, original.text);
  expect(
    actual.right - actual.left,
    closeTo(original.right - original.left, 1e-6),
  );
  expect(
    actual.bottom - actual.top,
    closeTo(original.bottom - original.top, 1e-6),
  );
}

void main() {
  group('Bug being fixed: a tilted ATM photo breaks rowsFromLines', () {
    // Measured on the real fixture: naive bounding boxes still parse at
    // +-3 and +-5 degrees, and fail at +-7 degrees.
    for (final degrees in [7.0, -7.0]) {
      test('at $degrees deg naive boxes do NOT give the demo reading', () {
        final naive = _rotatedFixture(degrees).map(_naiveBox).toList();
        final reading = parseAtmScreen(rowsFromLines(naive));
        expect(_isDemoReading(reading), isFalse);
      });
    }
  });

  group('straightenLines: tilted real ATM capture reads the demo values', () {
    for (final degrees in [7.0, -7.0]) {
      test('rotated $degrees deg gives 4000 / 220 / 30.86 / 5.50 / 4220 / '
          '144.71', () {
        final lines = straightenLines(_rotatedFixture(degrees));
        _expectDemoReading(parseAtmScreen(rowsFromLines(lines)));
      });

      test('rotated $degrees deg keeps every line and its box size', () {
        final lines = straightenLines(_rotatedFixture(degrees));
        expect(lines, hasLength(atmRealIosLines.length));
        for (var i = 0; i < lines.length; i++) {
          _expectSameSize(lines[i], atmRealIosLines[i]);
        }
      });
    }
  });

  group('straightenLines: un-rotated input is unchanged', () {
    test('boxes equal the originals within 1e-6', () {
      final quads = atmRealIosLines
          .map((l) => OcrQuad(text: l.text, corners: _corners(l)))
          .toList();
      final lines = straightenLines(quads);
      expect(lines, hasLength(atmRealIosLines.length));
      for (var i = 0; i < lines.length; i++) {
        final a = lines[i];
        final o = atmRealIosLines[i];
        expect(a.text, o.text);
        expect(a.left, closeTo(o.left, 1e-6));
        expect(a.top, closeTo(o.top, 1e-6));
        expect(a.right, closeTo(o.right, 1e-6));
        expect(a.bottom, closeTo(o.bottom, 1e-6));
      }
    });

    test('un-rotated real capture still reads the demo values', () {
      final quads = atmRealIosLines
          .map((l) => OcrQuad(text: l.text, corners: _corners(l)))
          .toList();
      _expectDemoReading(parseAtmScreen(rowsFromLines(straightenLines(quads))));
    });
  });

  group('straightenLines: tilt is the median, not the mean', () {
    test('one line rotated 40 deg among lines at 7 deg does not move the '
        'estimate', () {
      const outlierIndex = 0;
      final quads = _rotatedFixture(7);
      final o = atmRealIosLines[outlierIndex];
      quads[outlierIndex] = _rotatedQuad(
        o,
        40,
        cx: (o.left + o.right) / 2,
        cy: (o.top + o.bottom) / 2,
      );
      final lines = straightenLines(quads);
      expect(lines, hasLength(atmRealIosLines.length));
      for (var i = 0; i < lines.length; i++) {
        if (i == outlierIndex) continue;
        _expectSameSize(lines[i], atmRealIosLines[i]);
      }
    });
  });

  group('straightenLines: degenerate input', () {
    test('empty list gives an empty list', () {
      expect(straightenLines(const []), isEmpty);
    });

    test('a 3-corner quad is skipped, valid quads are kept', () {
      final lines = straightenLines(const [
        OcrQuad(text: 'Withdraw', corners: [(10, 10), (110, 10), (110, 40)]),
        OcrQuad(
          text: 'Access fee',
          corners: [(10, 60), (110, 60), (110, 90), (10, 90)],
        ),
      ]);
      expect(lines, hasLength(1));
      expect(lines.single.text, 'Access fee');
      expect(lines.single.left, closeTo(10, 1e-6));
      expect(lines.single.top, closeTo(60, 1e-6));
      expect(lines.single.right, closeTo(110, 1e-6));
      expect(lines.single.bottom, closeTo(90, 1e-6));
    });

    test('only a 3-corner quad gives an empty list', () {
      expect(
        straightenLines(const [
          OcrQuad(text: 'Withdraw', corners: [(10, 10), (110, 10), (110, 40)]),
        ]),
        isEmpty,
      );
    });
  });
}
