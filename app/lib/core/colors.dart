import 'package:flutter/painting.dart';

/// Color tokens. Single source: docs/DESIGN.md `colors`.
abstract final class AppColors {
  static const primary = Color(0xFF19D873);
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

  // Depth and floating chrome (DESIGN.md "Elevation & Depth").
  static const shadow = Color(0xFF111418);
  static const glassFill = Color(0xB8FFFFFF);
  static const glassBorder = Color(0x0F111418);
  static const dockFill = Color(0xE6F2F4F6);
  static const tabIndicator = Color(0x12111418);

  // Camera screens (DESIGN.md: glass only for camera controls).
  static const cameraBackground = Color(0xFF000000);
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
