/// Spacing, radius and size tokens. Single source: docs/DESIGN.md.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double screenMargin = 16;
  static const double cardGap = 12;
  static const double cardPadding = 20;
  static const double heroCardPadding = 22;
  static const double sheetPadding = 28;
  static const double chipPadding = 6;

  // Zones and groups (DESIGN.md "Layout").
  static const double zoneGap = 32;
  static const double groupGap = 12;
  static const double sectionHeaderTop = 28;
  static const double sectionHeaderBottom = 10;
  static const double sectionHeaderInset = 4;
  static const double groupPaddingH = 20;
  static const double groupPaddingV = 8;
  static const double rowPaddingV = 14;
  static const double footerGap = 8;
  static const double rowIconTextInset = 72;
}

abstract final class AppRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double sheet = 28;
  static const double full = 9999;
}

abstract final class AppSizes {
  static const double buttonHeight = 56;
  static const double minTouchTarget = 48;
  static const double iconTile = 44;

  /// Icon tile inside a group row; the hairline then starts at 72.
  static const double rowIconTile = 40;

  /// Widest a row's amount may get, as a share of the row.
  static const double rowValueMaxFraction = 0.55;

  /// Widest a page's content gets on wide screens (unfolded Fold: 932 wide);
  /// the floating tab bar stays narrower still.
  static const double contentMaxWidth = 560;
  static const double tabBarMaxWidth = 480;

  /// Width split of a secondary and primary button side by side.
  static const int dockSecondaryFlex = 2;
  static const int dockPrimaryFlex = 3;

  /// Light edge along the top of raised shapes, and how far down it fades
  /// (fraction of the shape's height).
  static const double edgeLightWidth = 1;
  static const double edgeLightReach = 0.4;

  /// Smallest corner a nested shape may get under the concentric rule.
  static const double minNestedRadius = 8;

  /// The living coin: idle float, touch tilt, contact shadow.
  static const double coinFloat = 3;
  static const double coinTiltMax = 0.14;
  static const double coinPerspective = 0.0012;
  static const double coinShadowWidth = 0.7;
  static const double coinShadowHeight = 10;
  static const double coinShadowShrink = 0.12;
  static const double coinShadowFade = 0.35;

  /// Launch speed and gravity of the celebration coins, in logical pixels
  /// per animation (0..1), so the burst ends inside [AppMotion.coinPop].
  static const double coinPopSpeed = 260;
  static const double coinPopGravity = 520;

  /// The small coins that pop once when money is kept, and the coin that
  /// flies to the total on "Save to trip".
  static const double popCoin = 22;
  static const double flyCoin = 28;
  static const double flyArcBulge = 80;
  static const double iconTileGlyphRatio = 0.5;
  static const double tabBarHeight = 64;
  static const double tabBarInsetH = 16;
  static const double tabBarInsetBottom = 8;
  static const double tabIndicatorHeight = 56;
  static const double tabIcon = 24;
  static const double tabBlur = 24;
  static const double dockBlur = 20;
  static const double rowMinHeight = 56;
  static const double hairline = 0.5;
  static const double progressStroke = 2;
  static const double stepGlyph = 16;
  static const double shutter = 76;
  static const double cameraScrimHeight = 120;
  static const double heroCoin = 132;
  static const double heroCoinCompact = 88;

  /// Screens this short or shorter (the Fold cover, 737) use compact heroes.
  static const double compactHeight = 760;

  /// Scan frame: landscape like an ATM screen, centered a little above the
  /// middle so the controls below never cover it.
  static const double scanGuideAspect = 0.72;
  static const double scanGuideCenterY = 0.42;
  static const double scanGuideCorner = 32;
  static const double scanGuideStroke = 4;
  static const double priceScaleTrack = 8;
  static const double priceScaleMarker = 22;
  static const double priceScaleMarkerRing = 4;

  /// How far the price marker runs past its place before settling.
  static const double priceMarkerOvershoot = 4;

  /// Buttons: label inset from the edges, glyph size and gap.
  static const double buttonPaddingH = 16;
  static const double buttonIcon = 22;

  /// Peeking card stack (haggling): each card behind is this much smaller
  /// and lower, and fainter, than the one in front.
  static const List<double> stackScales = [0.95, 0.90];
  static const List<double> stackOffsets = [10, 20];
  static const List<double> stackOpacities = [1, 0.7];

  /// A landing card starts this far below its place.
  static const double landRise = 16;

  /// A card entering the stack starts this far below its place.
  static const double stackEnterRise = 24;
  static const double waveformHeight = 40;
  static const double waveformBar = 3;
  static const double waveformGap = 3;
  static const double waveformMinBar = 0.08;
  static const int waveformSamples = 80;

  /// Height kept free for the scan steps sheet (four steps), so the photo
  /// above it keeps a fixed size while steps arrive.
  static const double scanSheetReserve = 300;
  static const double cameraControl = 48;
  static const double cameraIcon = 24;
  static const double sheetHandleWidth = 36;
  static const double sheetHandleHeight = 4;
  static const double stepIcon = 24;
  static const double detectionStroke = 2.5;
  static const double glassBlur = 20;
  static const double darkCardMinHeight = 96;
}
