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
