import 'package:flutter/painting.dart';

/// Color tokens. Single source: docs/DESIGN.md `colors`.
abstract final class AppColors {
  static const primary = Color(0xFF19D873);

  /// Green buttons are lit from above: a lighter top to a deeper bottom.
  static const primaryTop = Color(0xFF2EE383);
  static const primaryBottom = Color(0xFF14CC6A);
  static const onPrimary = Color(0xFF04220F);
  static const primaryText = Color(0xFF00A85A);
  static const primaryOnDark = Color(0xFF19E07A);
  static const primaryContainer = Color(0xFFD9FBE8);
  static const primaryContainerEnd = Color(0xFFBFF3D6);
  static const onPrimaryContainer = Color(0xFF1B5E3A);

  static const background = Color(0xFFF2F4F6);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFE5E8EB);
  static const surfaceSunken = Color(0xFFF9FAFB);
  static const divider = Color(0xFFE5E8EB);
  static const handle = Color(0xFFD1D6DB);
  static const surfaceDark = Color(0xFF111418);
  static const onSurface = Color(0xFF111418);
  static const onSurfaceSecondary = Color(0xFF4E5968);
  static const onSurfaceTertiary = Color(0xFF6B7684);
  static const onSurfaceMuted = Color(0xFF8B95A1);
  static const onSurfaceDark = Color(0xFFFFFFFF);
  static const onSurfaceDarkSecondary = Color(0xFFB0B8C1);

  static const error = Color(0xFFFF3B5C);
  static const errorText = Color(0xFFD1173A);
  static const errorContainer = Color(0xFFFFE9EC);

  // Success field (DESIGN.md: a lighter green center).
  static const successCenter = Color(0xFF6FF0AC);
  static const onSuccess = Color(0xFF04220F);
  static const onSuccessSecondary = Color(0xFF1B5E3A);

  // Depth and floating chrome (DESIGN.md "Elevation & Depth").
  static const shadow = Color(0xFF111418);

  /// Shadow colour on the green success field.
  static const shadowGreen = Color(0xFF0A4D2C);

  /// Top of the dark gradient on dark buttons and the dark card.
  static const surfaceDarkTop = Color(0xFF1E232A);

  /// Light edges along the top of raised shapes.
  static const edgeLightOnDark = Color(0x1AFFFFFF);
  static const edgeLightOnTile = Color(0x4DFFFFFF);
  static const edgeLightOnGlass = Color(0x8CFFFFFF);

  /// The success field's drifting light (DESIGN.md "Success screen").
  static const auraLight = Color(0xFF5BE89A);
  static const auraDeep = Color(0xFF12C366);

  /// Contact shadow under the coin.
  static const coinShadow = Color(0xFF0A2A18);

  /// Light edge on green buttons (lighter than on tiles: the fill is bright).
  static const edgeLightOnGreen = Color(0x66FFFFFF);

  /// Peeking cards behind the dark card share its colour.
  static const stackCard = Color(0xFF2A3038);
  static const glassFill = Color(0xB8FFFFFF);

  /// Soft shadow under map pins.
  static const mapPinShadowAlpha = 0.25;

  /// Glass lifts the colour of what passes beneath it (saturation 1.6),
  /// so blurred content reads as light through glass, not grey fog.
  static const glassSaturate = <double>[
    1.4724,
    -0.4291,
    -0.0433,
    0.0000,
    0.0000,
    -0.1276,
    1.1709,
    -0.0433,
    0.0000,
    0.0000,
    -0.1276,
    -0.4291,
    1.5567,
    0.0000,
    0.0000,
    0.0000,
    0.0000,
    0.0000,
    1.0000,
    0.0000,
  ];
  static const glassBorder = Color(0x0F111418);
  static const dockFill = Color(0xE6F2F4F6);
  static const tabIndicator = Color(0x12111418);

  // Camera screens (DESIGN.md: glass only for camera controls).
  static const cameraBackground = Color(0xFF000000);
  static const cameraOutsideGuide = Color(0x73000000);
  static const cameraScrimTop = Color(0x73111418);
  static const cameraScrimEnd = Color(0x00111418);
  // Dark glass: legible over both bright and dark camera scenes.
  static const cameraGlass = Color(0x66111418);
  // Hairline around camera glass, so controls keep an edge on pure black.
  static const cameraGlassBorder = Color(0x33FFFFFF);
  // Hairline inside the dark card, separating the action from the reason.
  static const dividerOnDark = Color(0x1FFFFFFF);
  static const detectionFill = Color(0x2619D873);

  static const iconBlue = Color(0xFF2463F0);
  static const iconBlueLight = Color(0xFF5B9BFF);
  static const iconOrange = Color(0xFFFF6A1A);
  static const iconOrangeLight = Color(0xFFFFA45C);
  static const iconGreen = Color(0xFF0CB55C);
  static const iconGreenLight = Color(0xFF4BE08F);
  static const iconYellow = Color(0xFFFFAE00);
  static const iconYellowLight = Color(0xFFFFD66B);
}
