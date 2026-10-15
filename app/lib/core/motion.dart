import 'package:flutter/widgets.dart';

/// Motion tokens. Every duration and curve in the app comes from here.
abstract final class AppMotion {
  /// Small state changes: press feedback, chip toggles.
  static const quick = Duration(milliseconds: 150);

  /// A single element entering or changing: a scan step checking off.
  static const standard = Duration(milliseconds: 280);

  /// Larger moves: a sheet rising, a number counting up.
  static const emphasized = Duration(milliseconds: 450);

  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const move = Curves.easeInOutCubic;

  /// Returns [Duration.zero] when the system "reduce motion" setting is on.
  static Duration of(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}
