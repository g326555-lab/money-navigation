import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/colors.dart';
import '../core/elevation.dart';
import '../core/motion.dart';
import '../core/spacing.dart';

/// DESIGN.md price scale: a light grey track, a green segment for the usual
/// range and a white-ringed round marker for the asked price.
///
/// It explains the verdict as it draws: the usual range grows out from its
/// centre, then the marker leaves the middle of the range and slides to the
/// asked price, runs a few pixels past and settles. The marker turns red the
/// moment it leaves the range, with a selection tick, so the eye and the
/// hand both feel where "too much" begins. With reduce motion the final
/// scale shows at once.
class PriceScale extends StatefulWidget {
  const PriceScale({
    super.key,
    required this.low,
    required this.high,
    required this.asked,
  });

  final double low;
  final double high;
  final double asked;

  @override
  State<PriceScale> createState() => _PriceScaleState();
}

class _PriceScaleState extends State<PriceScale> with TickerProviderStateMixin {
  late final _range = AnimationController(
    vsync: this,
    duration: AppMotion.priceRangeGrow,
  );
  late final _marker = AnimationController(
    vsync: this,
    duration: AppMotion.priceMarkerSlide,
  )..addListener(_watchCrossing);

  bool _crossed = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _play();
    }
  }

  @override
  void didUpdateWidget(PriceScale old) {
    super.didUpdateWidget(old);
    if (old.low != widget.low ||
        old.high != widget.high ||
        old.asked != widget.asked) {
      _play();
    }
  }

  Future<void> _play() async {
    _crossed = false;
    if (MediaQuery.disableAnimationsOf(context)) {
      _range.value = 1;
      _marker.value = 1;
      return;
    }
    _range.value = 0;
    _marker.value = 0;
    await _range.forward().orCancel.catchError((_) {});
    if (mounted) _marker.forward();
  }

  /// One tick when the marker leaves the usual range on its way up.
  void _watchCrossing() {
    if (_crossed || widget.asked <= widget.high) return;
    final position = _markerValue(
      widget.low,
      widget.high,
      widget.asked,
      _marker.value,
    );
    if (position > widget.high) {
      _crossed = true;
      HapticFeedback.selectionClick();
    }
  }

  @override
  void dispose() {
    _range.dispose();
    _marker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.priceScaleMarker + AppSizes.priceMarkerOvershoot * 2,
      width: double.infinity,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _PriceScalePainter(
            low: widget.low,
            high: widget.high,
            asked: widget.asked,
            range: _range,
            marker: _marker,
          ),
        ),
      ),
    );
  }
}

/// Where the marker is, in price, at slide progress [t]: it travels from the
/// middle of the range to the asked price on [AppMotion.priceMarkerTravel]
/// of the time, then the overshoot is added in pixels by the painter.
double _markerValue(double low, double high, double asked, double t) {
  final start = (low + high) / 2;
  final travel = AppMotion.enter.transform(
    (t / AppMotion.priceMarkerTravel).clamp(0.0, 1.0),
  );
  return start + (asked - start) * travel;
}

/// The overshoot, 0 → 1 → 0, over the last part of the slide (a half sine,
/// eased so it leaves fast and lands softly).
double _overshoot(double t) {
  const from = AppMotion.priceMarkerTravel * 0.8;
  if (t <= from) return 0;
  final u = ((t - from) / (1 - from)).clamp(0.0, 1.0);
  return math.sin(math.pi * Curves.easeOut.transform(u));
}

class _PriceScalePainter extends CustomPainter {
  _PriceScalePainter({
    required this.low,
    required this.high,
    required this.asked,
    required this.range,
    required this.marker,
  }) : super(repaint: Listenable.merge([range, marker]));

  final double low;
  final double high;
  final double asked;
  final Animation<double> range;
  final Animation<double> marker;

  @override
  void paint(Canvas canvas, Size size) {
    // The scale spans from zero to a little past the larger of the asked
    // price and the range, so both are always on it.
    final max = (asked > high ? asked : high) * priceScaleHeadroom;
    const knob = AppSizes.priceScaleMarker / 2;
    // Keep the knob (and its overshoot) inside the box at either end.
    final left = knob;
    final width = size.width - knob * 2;
    double x(double v) => left + (v / max).clamp(0.0, 1.0) * width;
    final cy = size.height / 2;
    const track = AppSizes.priceScaleTrack;
    const radius = Radius.circular(track / 2);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, cy - track / 2, size.width, track),
        radius,
      ),
      Paint()..color = AppColors.surfaceDim,
    );

    // The usual range grows out from its centre.
    final grow = AppMotion.enter.transform(range.value);
    final centre = (x(low) + x(high)) / 2;
    final half = (x(high) - x(low)) / 2 * grow;
    if (half > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            centre - half,
            cy - track / 2,
            centre + half,
            cy + track / 2,
          ),
          radius,
        ),
        Paint()..color = AppColors.primary,
      );
    }

    // The marker appears with the range and waits at its centre.
    final value = _markerValue(low, high, asked, marker.value);
    final direction = asked >= (low + high) / 2 ? 1 : -1;
    final markerX =
        x(value) +
        direction * AppSizes.priceMarkerOvershoot * _overshoot(marker.value);
    final centreOffset = Offset(markerX, cy);
    final outer = knob * grow;
    if (outer <= 0) return;
    for (final s in AppElevation.knob) {
      canvas.drawCircle(
        centreOffset + s.offset,
        outer + s.spreadRadius,
        s.toPaint(),
      );
    }
    final above = value > high;
    canvas
      ..drawCircle(centreOffset, outer, Paint()..color = AppColors.surface)
      ..drawCircle(
        centreOffset,
        (outer - AppSizes.priceScaleMarkerRing).clamp(0.0, outer),
        Paint()..color = above ? AppColors.error : AppColors.surfaceDark,
      );
  }

  @override
  bool shouldRepaint(_PriceScalePainter old) =>
      old.low != low ||
      old.high != high ||
      old.asked != asked ||
      old.range != range ||
      old.marker != marker;
}

/// How far past the larger value the scale runs.
const priceScaleHeadroom = 1.15;
