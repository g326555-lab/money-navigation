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

  /// Pressed state of cards and buttons: in fast, out on a spring, so a
  /// release mid-press keeps its speed.
  static const pressedScale = 0.97;
  static const pressIn = Duration(milliseconds: 90);
  static const pressRelease = SpringDescription(
    mass: 1,
    stiffness: 420,
    damping: 33.6, // damping ratio 0.82
  );

  /// Odometer digits: each digit slides this fraction of its height, the
  /// rightmost first.
  static const digitRoll = Duration(milliseconds: 480);
  static const digitStagger = Duration(milliseconds: 30);
  static const digitTravel = 0.6;

  /// The living coin's idle float, one full cycle.
  static const coinFloat = Duration(milliseconds: 3200);

  /// The success field's light drifts over this long, back and forth.
  static const auraDrift = Duration(seconds: 14);
  static const auraTravel = 0.06;

  /// Coins that pop once when money is kept; the whole burst ends inside
  /// [coinPop].
  static const coinPop = Duration(milliseconds: 900);
  static const coinPopCount = 6;

  /// Celebration coins: speed drop between neighbours, and where in the
  /// burst (0..1) they start to fade.
  static const coinPopSpeedStep = 0.18;
  static const coinPopFadeFrom = 0.66;

  /// Half-angle of the fan the celebration coins launch on, in radians.
  static const coinPopFan = 0.9;

  /// The coin springs back after a touch tilts it.
  static const coinTiltSpring = SpringDescription(
    mass: 1,
    stiffness: 260,
    damping: 22.6, // damping ratio 0.7
  );

  /// The success field's light centre and reach (see AuraField).
  static const auraCenter = Alignment(0, -0.55);
  static const auraRadius = 0.9;

  /// Hero entrance: the number pops over the last part of the count, the
  /// coin fades in over the first part.
  static const heroPop = Interval(0.6, 1, curve: settle);
  static const heroCoinFade = Interval(0, 0.4, curve: enter);

  /// "Save to trip": a coin flies on an arc to the total, which then bumps.
  static const flyToTotal = Duration(milliseconds: 550);
  static const totalBump = 1.10;
  static const flyEndScale = 0.6;

  /// Pressed state of the shutter's inner disc (the ring stays still).
  static const shutterPressedScale = 0.86;

  /// Scale the hero amount counts up at before it settles to full size.
  static const heroSettleFrom = 0.96;

  /// The coin grows in from this scale as the amount lands.
  static const coinStartScale = 0.6;

  /// Delay between detection boxes drawing in, as a fraction of the whole
  /// draw-in, so the eye follows them top to bottom.
  static const boxStagger = 0.12;

  /// Longest the whole set of detection boxes may take to draw in.
  static const boxesMax = Duration(milliseconds: 500);

  /// Price scale: the usual range grows out from its centre, then the
  /// asked-price marker slides to its place, overshoots a little and
  /// settles (see AppSizes.priceMarkerOvershoot).
  static const priceRangeGrow = Duration(milliseconds: 420);
  static const priceMarkerSlide = Duration(milliseconds: 650);

  /// Share of the marker slide spent travelling; the rest is the overshoot
  /// and settle.
  static const priceMarkerTravel = 0.72;

  /// A new phrase card entering the top of the haggling card stack.
  static const cardEnter = SpringDescription(
    mass: 1,
    stiffness: 380,
    damping: 33.5, // damping ratio 0.86
  );

  /// The "Say it" button breathes once when the counter-offer is ready,
  /// after its card has landed.
  static const sayItBreath = Duration(milliseconds: 700);
  static const sayItBreathDelay = Duration(milliseconds: 350);
  static const sayItBreathScale = 1.03;

  /// A raised card landing on a hero moment (the Press card on the success
  /// field): about 550 ms with a slight overshoot (bounce ~0.18).
  static const landSpring = SpringDescription(
    mass: 1,
    stiffness: 200,
    damping: 23.2, // damping ratio 0.82
  );
  static const landFromScale = 0.98;

  /// The Press card lands as the hero amount settles.
  static const pressCardDelay = Duration(milliseconds: 300);

  /// Demo switch: a curtain covers the app, the language, currency and
  /// records change under it, the new traveler's name shows, the curtain
  /// lifts. One transition, so the three never change one by one.
  static const demoCurtainIn = Duration(milliseconds: 220);
  static const demoNameIn = Duration(milliseconds: 280);
  static const demoNameHold = Duration(milliseconds: 650);
  static const demoCurtainOut = Duration(milliseconds: 420);
  static const demoNameRise = Offset(0, 0.3);

  /// Trip map: the selected-place card drops in from just above its place
  /// (a fraction of its own height) while it fades in.
  static const mapCardDrop = Offset(0, -0.15);

  /// A selection check grows in from this scale.
  static const checkFrom = 0.6;

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
