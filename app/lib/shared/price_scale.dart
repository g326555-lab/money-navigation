import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/colors.dart';
import '../core/elevation.dart';
import '../core/formatters.dart';
import '../core/motion.dart';
import '../core/spacing.dart';
import '../core/typography.dart';
import '../l10n/app_localizations.dart';
import '../rules/haggle.dart';

/// "Is this price fair?" at a glance, the way fare and car-price tools show
/// it: a plain sentence with the verdict first, then a ruler that proves it.
///
/// The ruler is zoomed onto the usual range (it never starts at zero), split
/// into three named zones (cheap, usual, high), with the range's end prices
/// written under its edges and the asked price written on its marker. An
/// optional tick shows what the traveler paid before, and a small notch the
/// counter-offer. Words carry the meaning; colour only backs them up.
///
/// Motion explains the verdict: the zones fade in, then the marker slides
/// from the middle of the usual range to the asked price, with a selection
/// tick when it crosses into "high". Reduce motion shows the final state.
class PriceScale extends StatefulWidget {
  const PriceScale({
    super.key,
    required this.low,
    required this.high,
    required this.asked,
    this.verdict,
    this.unit = '',
    this.counter,
    this.lastPaid,
  });

  final double low;
  final double high;
  final double asked;

  /// The verdict from the rules, so the sentence and the drawing agree.
  /// Without it the ruler is drawn with no sentence above it.
  final HaggleVerdict? verdict;

  /// The unit the prices are for, as shown to the reader ("per kilo").
  final String unit;
  final double? counter;
  final double? lastPaid;

  @override
  State<PriceScale> createState() => _PriceScaleState();
}

class _PriceScaleState extends State<PriceScale> with TickerProviderStateMixin {
  late final _zones = AnimationController(
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
      _zones.value = 1;
      _marker.value = 1;
      return;
    }
    _zones.value = 0;
    _marker.value = 0;
    await _zones.forward().orCancel.catchError((_) {});
    if (mounted) _marker.forward();
  }

  double get _markerPrice {
    final start = (widget.low + widget.high) / 2;
    final t = AppMotion.enter.transform(_marker.value);
    return start + (widget.asked - start) * t;
  }

  void _watchCrossing() {
    if (_crossed || widget.asked <= widget.high) return;
    if (_markerPrice > widget.high) {
      _crossed = true;
      HapticFeedback.selectionClick();
    }
  }

  @override
  void dispose() {
    _zones.dispose();
    _marker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final w = widget;
    final window = priceWindow(
      low: w.low,
      high: w.high,
      asked: w.asked,
      lastPaid: w.lastPaid,
    );
    String money(double v) => AppFormat.roundedAmount(v, marketCurrency);
    String number(double v) => AppFormat.roundedNumber(v);
    final over = percentOverUsual(w.asked, w.high);
    final verdict = w.verdict;
    final high = verdict?.verdict == PriceVerdict.high;
    final sentence = switch (verdict?.verdict) {
      null => null,
      PriceVerdict.high => l10n.priceSentenceHigh(
        money(w.asked),
        money(verdict!.overBy),
        // Whole percents once the gap is large: "about 1,036%".
        over >= priceWholePercentFrom
            ? AppFormat.percentWhole(over)
            : AppFormat.roundedPercent(over),
      ),
      PriceVerdict.fair => l10n.priceSentenceFair(money(w.asked)),
      PriceVerdict.low => l10n.priceSentenceLow(money(w.asked)),
    };
    final zoneStyle = type.caption.copyWith(color: AppColors.onSurfaceTertiary);
    final tickStyle = type.caption.copyWith(
      color: AppColors.onSurfaceSecondary,
      fontWeight: FontWeight.w700,
    );
    final semantics = [
      l10n.priceSemanticsRange(number(w.low), number(w.high), w.unit),
      ?sentence,
      if (w.counter != null) l10n.priceSemanticsCounter(money(w.counter!)),
      if (w.lastPaid != null) l10n.priceYouPaid(money(w.lastPaid!)),
    ].join('. ');

    return Semantics(
      label: semantics,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sentence != null) ...[
            Text(
              sentence,
              style: type.rowTitle.copyWith(
                color: high ? AppColors.errorText : AppColors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              const knob = AppSizes.priceScaleMarker / 2;
              double x(double v) {
                final t = ((v - window.from) / (window.to - window.from)).clamp(
                  0.0,
                  1.0,
                );
                return knob + t * (width - knob * 2);
              }

              final pinH = AppSizes.pricePinHeight;
              return AnimatedBuilder(
                animation: Listenable.merge([_zones, _marker]),
                builder: (context, _) {
                  final markerX = x(_markerPrice);
                  final settled = _marker.value >= 1;
                  final pinText = l10n.priceAsked(number(w.asked));
                  final pinWidth = _textWidth(pinText, tickStyle, context);
                  final pinLeft = (markerX - pinWidth / 2).clamp(
                    0.0,
                    width - pinWidth,
                  );
                  final fade = AppMotion.enter.transform(_zones.value);
                  return SizedBox(
                    width: width,
                    height:
                        pinH +
                        AppSizes.priceScaleMarker +
                        AppSizes.priceLabelRows *
                            (zoneStyle.fontSize! * (zoneStyle.height ?? 1)) +
                        (w.lastPaid == null ? 0 : AppSpacing.lg),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // The asked price, written on its marker.
                        Positioned(
                          left: pinLeft,
                          top: 0,
                          child: Opacity(
                            opacity: settled ? 1 : 0,
                            child: Text(
                              pinText,
                              style: tickStyle.copyWith(
                                color: high
                                    ? AppColors.errorText
                                    : AppColors.onSurface,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: pinH,
                          height: AppSizes.priceScaleMarker,
                          child: Opacity(
                            opacity: fade,
                            child: CustomPaint(
                              painter: _RulerPainter(
                                low: x(w.low),
                                high: x(w.high),
                                counter: w.counter == null
                                    ? null
                                    : x(w.counter!),
                                lastPaid: w.lastPaid == null
                                    ? null
                                    : x(w.lastPaid!),
                                marker: markerX,
                                markerAbove: _markerPrice > w.high,
                                markerBelow: _markerPrice < w.low,
                                breakRight: window.farAbove,
                                breakLeft: window.farBelow,
                              ),
                            ),
                          ),
                        ),
                        // End prices of the usual range, under its edges.
                        for (final v in [w.low, w.high])
                          _centred(
                            x(v),
                            pinH + AppSizes.priceScaleMarker,
                            number(v),
                            tickStyle,
                            width,
                            fade,
                          ),
                        // Zone names, centred in each zone.
                        ..._zoneWords(
                          l10n,
                          x,
                          width,
                          window,
                          pinH + AppSizes.priceScaleMarker,
                          zoneStyle,
                          fade,
                        ),
                        if (w.lastPaid case final paid?)
                          _centred(
                            x(paid),
                            pinH +
                                AppSizes.priceScaleMarker +
                                AppSizes.priceLabelRows *
                                    (zoneStyle.fontSize! *
                                        (zoneStyle.height ?? 1)),
                            l10n.priceYouPaid(number(paid)),
                            zoneStyle,
                            width,
                            fade,
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _zoneWords(
    AppLocalizations l10n,
    double Function(double) x,
    double width,
    ({double from, double to, bool farAbove, bool farBelow}) window,
    double top,
    TextStyle style,
    double fade,
  ) {
    final w = widget;
    final rowTop = top + (style.fontSize! * (style.height ?? 1));
    final lowX = x(w.low);
    final highX = x(w.high);
    // The usual zone is always named; a neighbour whose name would run
    // into it stays unnamed.
    final usualText = l10n.priceZoneUsual(w.unit);
    final usualStyle = style.copyWith(color: AppColors.primaryText);
    final usualW = _textWidth(usualText, usualStyle, context);
    final usualLeft = ((lowX + highX) / 2 - usualW / 2).clamp(
      0.0,
      (width - usualW).clamp(0.0, width),
    );
    final usualRight = usualLeft + usualW;
    Widget? side(double from, double to, String text, TextStyle style) {
      final tw = _textWidth(text, style, context);
      final cx = (from + to) / 2;
      final left = cx - tw / 2;
      final clear =
          left + tw + AppSpacing.sm <= usualLeft ||
          left >= usualRight + AppSpacing.sm;
      if (!clear || left < 0 || left + tw > width) return null;
      return _centred(cx, rowTop, text, style, width, fade);
    }

    return [
      ?side(
        0,
        lowX,
        window.farBelow ? l10n.priceZoneFarBelow : l10n.priceZoneCheap,
        style,
      ),
      _centred((lowX + highX) / 2, rowTop, usualText, usualStyle, width, fade),
      ?side(
        highX,
        width,
        window.farAbove ? l10n.priceZoneFarAbove : l10n.priceZoneHigh,
        style.copyWith(color: AppColors.errorText),
      ),
    ];
  }

  Widget _centred(
    double cx,
    double top,
    String text,
    TextStyle style,
    double width,
    double opacity,
  ) {
    final tw = _textWidth(text, style, context);
    return Positioned(
      left: (cx - tw / 2).clamp(0.0, (width - tw).clamp(0.0, width)),
      top: top,
      child: Opacity(
        opacity: opacity,
        child: Text(text, style: style, maxLines: 1),
      ),
    );
  }

  static double _textWidth(String text, TextStyle style, BuildContext c) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(c),
      textScaler: MediaQuery.textScalerOf(c),
      maxLines: 1,
    )..layout();
    return painter.width;
  }
}

/// The track in three zones, the counter-offer notch, the past-price tick
/// and the marker.
class _RulerPainter extends CustomPainter {
  _RulerPainter({
    required this.low,
    required this.high,
    required this.counter,
    required this.lastPaid,
    required this.marker,
    required this.markerAbove,
    required this.markerBelow,
    required this.breakRight,
    required this.breakLeft,
  });

  final double low;
  final double high;
  final double? counter;
  final double? lastPaid;
  final double marker;
  final bool markerAbove;
  final bool markerBelow;
  final bool breakRight;
  final bool breakLeft;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    const track = AppSizes.priceScaleTrack;
    const r = Radius.circular(track / 2);
    final top = cy - track / 2;
    final bottom = cy + track / 2;

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTRB(0, top, low, bottom),
        topLeft: r,
        bottomLeft: r,
      ),
      Paint()..color = AppColors.surfaceDim,
    );
    canvas.drawRect(
      Rect.fromLTRB(low, top, high, bottom),
      Paint()..color = AppColors.primary,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTRB(high, top, size.width, bottom),
        topRight: r,
        bottomRight: r,
      ),
      Paint()..color = AppColors.errorContainer,
    );

    // The window was capped: two short cuts say "the scale jumps here".
    final cut = Paint()
      ..color = AppColors.surface
      ..strokeWidth = AppSizes.priceBreakStroke;
    void cuts(double x) {
      for (final dx in [-AppSizes.priceBreakGap, AppSizes.priceBreakGap]) {
        canvas.drawLine(
          Offset(x + dx - AppSizes.priceBreakSlant, bottom + 1),
          Offset(x + dx + AppSizes.priceBreakSlant, top - 1),
          cut,
        );
      }
    }

    if (breakRight) cuts(size.width - AppSizes.priceScaleMarker * 1.5);
    if (breakLeft) cuts(AppSizes.priceScaleMarker * 1.5);

    // Counter-offer: a notch above the track where we suggest asking.
    if (counter case final c?) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(c, top - AppSizes.priceNotch / 2),
            width: AppSizes.priceNotchWidth,
            height: AppSizes.priceNotch,
          ),
          const Radius.circular(AppSizes.priceNotchWidth / 2),
        ),
        Paint()..color = AppColors.primaryText,
      );
    }

    // What the traveler paid before: a hollow tick below the track.
    if (lastPaid case final p?) {
      canvas.drawCircle(
        Offset(p, bottom + AppSizes.priceNotch),
        AppSizes.priceNotchWidth,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = AppSizes.priceBreakStroke
          ..color = AppColors.onSurfaceSecondary,
      );
    }

    final centre = Offset(marker, cy);
    const knob = AppSizes.priceScaleMarker / 2;
    for (final s in AppElevation.knob) {
      canvas.drawCircle(centre + s.offset, knob + s.spreadRadius, s.toPaint());
    }
    canvas
      ..drawCircle(centre, knob, Paint()..color = AppColors.surface)
      ..drawCircle(
        centre,
        knob - AppSizes.priceScaleMarkerRing,
        Paint()
          ..color = markerAbove
              ? AppColors.error
              : markerBelow
              ? AppColors.primaryText
              : AppColors.surfaceDark,
      );
  }

  @override
  bool shouldRepaint(_RulerPainter old) =>
      old.marker != marker ||
      old.low != low ||
      old.high != high ||
      old.counter != counter ||
      old.lastPaid != lastPaid ||
      old.breakLeft != breakLeft ||
      old.breakRight != breakRight;
}

/// From this percent up the sentence rounds to whole percents.
const priceWholePercentFrom = 100.0;
