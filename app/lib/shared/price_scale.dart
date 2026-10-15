import 'package:flutter/material.dart';

import '../core/colors.dart';
import '../core/spacing.dart';

/// DESIGN.md price scale: a light gray track, a green segment for the usual
/// range and a round marker for the asked price (red when above the range).
class PriceScale extends StatelessWidget {
  const PriceScale({
    super.key,
    required this.low,
    required this.high,
    required this.asked,
    required this.progress,
  });

  final double low;
  final double high;
  final double asked;

  /// 0 to 1: the marker slides from the range to the asked price.
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.priceScaleMarker,
      width: double.infinity,
      child: CustomPaint(
        painter: _PriceScalePainter(low, high, asked, progress),
      ),
    );
  }
}

class _PriceScalePainter extends CustomPainter {
  _PriceScalePainter(this.low, this.high, this.asked, this.progress);

  final double low;
  final double high;
  final double asked;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    // The scale spans from zero to a little past the larger of the asked
    // price and the range, so both are always on it.
    final max = (asked > high ? asked : high) * priceScaleHeadroom;
    double x(double v) => (v / max).clamp(0.0, 1.0) * size.width;
    final cy = size.height / 2;
    const track = AppSizes.priceScaleTrack;
    final radius = const Radius.circular(track / 2);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, cy - track / 2, size.width, track),
        radius,
      ),
      Paint()..color = AppColors.surfaceDim,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(x(low), cy - track / 2, x(high), cy + track / 2),
        radius,
      ),
      Paint()..color = AppColors.primary,
    );

    final start = x((low + high) / 2);
    final markerX = start + (x(asked) - start) * progress;
    final above = asked > high;
    final marker = AppSizes.priceScaleMarker / 2;
    canvas
      ..drawCircle(
        Offset(markerX, cy),
        marker,
        Paint()..color = AppColors.surface,
      )
      ..drawCircle(
        Offset(markerX, cy),
        marker - AppSizes.priceScaleMarkerRing,
        Paint()..color = above ? AppColors.error : AppColors.surfaceDark,
      );
  }

  @override
  bool shouldRepaint(_PriceScalePainter old) =>
      old.low != low ||
      old.high != high ||
      old.asked != asked ||
      old.progress != progress;
}

/// How far past the larger value the scale runs.
const priceScaleHeadroom = 1.15;
