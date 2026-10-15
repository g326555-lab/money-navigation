import 'package:flutter/widgets.dart';

/// Motion tokens. Every duration and curve in the app comes from here.
abstract final class AppMotion {
  /// Small state changes: press feedback, chip toggles.
  static const quick = Duration(milliseconds: 150);

  /// A single element entering or changing: a scan step checking off.
  static const standard = Duration(milliseconds: 280);

  /// Larger moves: a sheet rising, a number counting up.
  static const emphasized = Duration(milliseconds: 450);

  /// How long the finished steps stay readable before the verdict opens.
  /// Applied after the real work is done; it never stands in for work.
  static const resultHold = Duration(milliseconds: 300);

  /// Slide distances, as a fraction of the moving element's own size.
  static const stepRise = Offset(0, 0.25);
  static const sheetRise = Offset(0, 1);

  /// Pressed state of tappable chrome.
  static const pressedScale = 0.94;

  /// Pressed state of the shutter's inner disc (the ring stays still).
  static const shutterPressedScale = 0.86;

  /// Scale the hero amount counts up at before it settles to full size.
  static const heroSettleFrom = 0.96;

  /// Delay between detection boxes drawing in, as a fraction of the whole
  /// draw-in, so the eye follows them top to bottom.
  static const boxStagger = 0.12;

  /// Longest the whole set of detection boxes may take to draw in.
  static const boxesMax = Duration(milliseconds: 500);

  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const move = Curves.easeInOutCubic;

  /// Arrival with a slight overshoot: a check landing, a number settling,
  /// a detection box snapping onto the text. Used only for those moments.
  static const settle = Curves.easeOutBack;

  /// Returns [Duration.zero] when the system "reduce motion" setting is on.
  static Duration of(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}
