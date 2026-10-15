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
  static const surfaceDark = Color(0xFF111418);
  static const onSurface = Color(0xFF111418);
  static const onSurfaceSecondary = Color(0xFF4E5968);
  static const onSurfaceTertiary = Color(0xFF6B7684);
  static const onSurfaceMuted = Color(0xFF8B95A1);
  static const onSurfaceDark = Color(0xFFFFFFFF);

  static const error = Color(0xFFFF3B5C);
  static const errorText = Color(0xFFD1173A);
  static const errorContainer = Color(0xFFFFE9EC);

  static const iconBlue = Color(0xFF2463F0);
  static const iconBlueLight = Color(0xFF5B9BFF);
  static const iconOrange = Color(0xFFFF6A1A);
  static const iconOrangeLight = Color(0xFFFFA45C);
  static const iconGreen = Color(0xFF0CB55C);
  static const iconGreenLight = Color(0xFF4BE08F);
  static const iconYellow = Color(0xFFFFAE00);
  static const iconYellowLight = Color(0xFFFFD66B);
}
