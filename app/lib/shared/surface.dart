import 'package:flutter/widgets.dart';

import '../core/colors.dart';
import '../core/spacing.dart';

/// How far the nearest [PressDepth] is pressed in, 0 (up) to 1 (down).
/// Raised surfaces read it to tighten their shadow while pressed.
class PressDepth extends InheritedNotifier<Animation<double>> {
  const PressDepth({
    super.key,
    required Animation<double> depth,
    required super.child,
  }) : super(notifier: depth);

  static double of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<PressDepth>()
          ?.notifier
          ?.value ??
      0;
}

/// A shape on the page: continuous-curvature (superellipse) corners, a fill,
/// layered shadows that tighten while pressed, and an optional light edge
/// along the top, as if lit from above.
class Surface extends StatelessWidget {
  const Surface({
    super.key,
    required this.radius,
    required this.child,
    this.color,
    this.gradient,
    this.shadows = const [],
    this.pressedShadows,
    this.edgeLight,
    this.padding,
    this.clip = false,
  });

  final double radius;
  final Widget child;
  final Color? color;
  final Gradient? gradient;
  final List<BoxShadow> shadows;

  /// Shadows when fully pressed; defaults to the first (contact) layer only.
  final List<BoxShadow>? pressedShadows;

  /// Colour of the 1 px light edge at the top; it fades out downwards.
  final Color? edgeLight;
  final EdgeInsetsGeometry? padding;

  /// Clip the child to the shape (photos, blurs).
  final bool clip;

  static ShapeBorder shape(double radius) =>
      RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(radius));

  @override
  Widget build(BuildContext context) {
    final pressed = PressDepth.of(context);
    final rest = shadows;
    final down = pressedShadows ?? rest.take(1).toList();
    final current = pressed == 0
        ? rest
        : BoxShadow.lerpList(rest, down, pressed) ?? rest;
    Widget content = padding == null
        ? child
        : Padding(padding: padding!, child: child);
    if (clip) {
      content = ClipRSuperellipse(
        borderRadius: BorderRadius.circular(radius),
        child: content,
      );
    }
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape(radius),
        color: gradient == null ? color : null,
        gradient: gradient,
        shadows: current,
      ),
      position: DecorationPosition.background,
      child: edgeLight == null
          ? content
          : CustomPaint(
              foregroundPainter: _EdgeLight(radius: radius, color: edgeLight!),
              child: content,
            ),
    );
  }
}

/// A hairline that follows the top of the shape and fades out by
/// [AppSizes.edgeLightReach] of its height.
class _EdgeLight extends CustomPainter {
  _EdgeLight({required this.radius, required this.color});

  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = AppSizes.edgeLightWidth / 2;
    final rect = (Offset.zero & size).deflate(inset);
    final path = Path()
      ..addRSuperellipse(
        RSuperellipse.fromRectAndRadius(rect, Radius.circular(radius - inset)),
      );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppSizes.edgeLightWidth
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0, AppSizes.edgeLightReach],
        colors: [color, color.withValues(alpha: 0)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_EdgeLight old) =>
      old.radius != radius || old.color != color;
}

/// Colours of the light edge on each kind of surface.
abstract final class EdgeLights {
  static const onDark = AppColors.edgeLightOnDark;
  static const onTile = AppColors.edgeLightOnTile;
  static const onGlass = AppColors.edgeLightOnGlass;
  static const onGreen = AppColors.edgeLightOnGreen;
}
