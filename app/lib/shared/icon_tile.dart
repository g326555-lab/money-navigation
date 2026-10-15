import 'package:flutter/widgets.dart';

import '../core/colors.dart';
import '../core/elevation.dart';
import '../core/spacing.dart';
import 'surface.dart';

/// Glossy rounded square with a white line glyph (DESIGN.md "Icon tile").
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    required this.light,
    required this.dark,
    this.size = AppSizes.rowIconTile,
  });

  /// Blue tile, used for anything scanned.
  const IconTile.blue({
    super.key,
    required this.icon,
    this.size = AppSizes.rowIconTile,
  }) : light = AppColors.iconBlueLight,
       dark = AppColors.iconBlue;

  /// Orange tile, used for anything heard at a market.
  const IconTile.orange({
    super.key,
    required this.icon,
    this.size = AppSizes.rowIconTile,
  }) : light = AppColors.iconOrangeLight,
       dark = AppColors.iconOrange;

  final IconData icon;
  final Color light;
  final Color dark;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Surface(
      radius: AppRadius.sm,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [light, dark],
      ),
      shadows: AppElevation.e1Tinted(dark),
      edgeLight: EdgeLights.onTile,
      child: SizedBox.square(
        dimension: size,
        child: Icon(
          icon,
          size: size * AppSizes.iconTileGlyphRatio,
          color: AppColors.onSurfaceDark,
        ),
      ),
    );
  }
}
