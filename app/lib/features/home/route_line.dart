import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/elevation.dart';
import '../../core/formatters.dart';
import '../../core/motion.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/haggle.dart' show marketCurrency;
import '../../rules/trip_route.dart';
import '../../rules/trip_ledger.dart';
import '../../shared/pressable.dart';
import 'home_metrics.dart';

/// The trip drawn as a route: one green dot per place where money was kept,
/// joined by the green line, ending in a hollow "next stop".
class RouteLine extends StatefulWidget {
  const RouteLine({
    super.key,
    required this.stops,
    this.onPressed,
    this.semanticLabel,
  });

  final List<RouteStop> stops;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  State<RouteLine> createState() => _RouteLineState();
}

class _RouteLineState extends State<RouteLine>
    with SingleTickerProviderStateMixin {
  late final _draw = AnimationController(
    vsync: this,
    duration: AppMotion.emphasized,
  );
  int _drawnStops = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _redraw();
  }

  @override
  void didUpdateWidget(RouteLine old) {
    super.didUpdateWidget(old);
    _redraw();
  }

  /// Draws the line once, and again only when a stop is added.
  void _redraw() {
    if (widget.stops.length == _drawnStops) return;
    final from = _drawnStops == 0 ? 0.0 : _draw.value;
    _drawnStops = widget.stops.length;
    if (MediaQuery.disableAnimationsOf(context)) {
      _draw.value = 1;
    } else {
      _draw.forward(from: from == 1 ? HomeMetrics.routeRedrawFrom : from);
    }
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final stops = widget.stops;
    final labels = [
      for (final s in stops)
        _StopLabel(
          title: s.day != null
              ? l10n.tripDayShort(s.day!)
              : s.placeName ?? _kindName(l10n, s.kind),
          value: l10n.saveKeptValue(
            AppFormat.roundedAmount(s.keptThb, marketCurrency),
          ),
          sample: s.isSample,
        ),
    ];
    final semantics = [
      for (final l in labels) '${l.title} ${l.value}',
      l10n.homeRouteNext,
    ].join(', ');

    return Pressable(
      onPressed: widget.onPressed,
      semanticLabel: widget.semanticLabel ?? semantics,
      child: Semantics(
        label: semantics,
        container: true,
        excludeSemantics: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final points = stops.length + 1;
            final step = width / points;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: HomeMetrics.routeDotRow,
                  width: width,
                  child: AnimatedBuilder(
                    animation: _draw,
                    builder: (context, _) => CustomPaint(
                      painter: _RoutePainter(
                        stops: stops.length,
                        step: step,
                        progress: AppMotion.enter.transform(_draw.value),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AnimatedBuilder(
                  animation: _draw,
                  builder: (context, _) {
                    final progress = AppMotion.enter.transform(_draw.value);
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final (i, label) in labels.indexed)
                          SizedBox(
                            width: step,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                right: AppSpacing.xs,
                              ),
                              child: _animatedLabel(
                                i: i,
                                stops: stops.length,
                                step: step,
                                progress: progress,
                                child: label,
                              ),
                            ),
                          ),
                        SizedBox(
                          width: step,
                          child: Text(
                            l10n.homeRouteNext,
                            maxLines: 2,
                            style: type.label.copyWith(
                              color: AppColors.onSurfaceSecondary,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Labels settle into full contrast as the route line reaches their stop.
  static Widget _animatedLabel({
    required int i,
    required int stops,
    required double step,
    required double progress,
    required Widget child,
  }) {
    if (stops <= 1 || progress >= 1 || step <= 0) return child;
    const r = HomeMetrics.routeDot / 2;
    final first = r;
    final last = r + (stops - 1) * step;
    final reach = first + (last - first) * progress;
    final x = r + i * step;
    final span = step * HomeMetrics.routeDotSettleSpan;
    final t = ((reach - x + span * 0.5) / span).clamp(0.0, 1.0);
    final eased = AppMotion.enter.transform(t);
    return Opacity(
      opacity: 0.45 + 0.55 * eased,
      child: Transform.translate(
        offset: Offset(0, (1 - eased) * (AppSpacing.xs / 2)),
        child: child,
      ),
    );
  }

  static String _kindName(AppLocalizations l10n, SaveKind kind) =>
      switch (kind) {
        SaveKind.atmConversion => l10n.homeRouteAtm,
        SaveKind.haggle => l10n.homeRouteMarket,
        SaveKind.terminalDcc => l10n.homeRouteTerminal,
      };
}

class _StopLabel extends StatelessWidget {
  const _StopLabel({
    required this.title,
    required this.value,
    required this.sample,
  });

  final String title;
  final String value;
  final bool sample;

  @override
  Widget build(BuildContext context) {
    final type = AppTypography.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A single long word (an airport name) must not break mid-word.
        title.contains(' ')
            ? Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: type.label.copyWith(color: AppColors.onSurface),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  maxLines: 1,
                  style: type.label.copyWith(color: AppColors.onSurface),
                ),
              ),
        const SizedBox(height: AppSpacing.xs / 2),
        Text(
          value,
          style: type.label.copyWith(
            color: sample ? AppColors.onSurfaceTertiary : AppColors.primaryText,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Dots at the left of each column; the line reaches the hollow last dot.
class _RoutePainter extends CustomPainter {
  _RoutePainter({
    required this.stops,
    required this.step,
    required this.progress,
  });

  final int stops;
  final double step;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    const r = HomeMetrics.routeDot / 2;
    final xs = [for (var i = 0; i <= stops; i++) r + i * step];
    final lastStop = xs[stops - 1 < 0 ? 0 : stops - 1];
    final end = xs.last;

    // The way ahead: a continuous quiet track from the first stop to the next.
    final track = Paint()
      ..color = AppColors.surfaceDim
      ..strokeWidth = HomeMetrics.routeStroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(xs.first, y), Offset(end - r, y), track);

    // The way travelled, drawn left to right.
    final reach = xs.first + (lastStop - xs.first) * progress;
    final line = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.primaryTop, AppColors.primaryBottom],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, y - r, size.width, r * 2))
      ..strokeWidth = HomeMetrics.routeStroke
      ..strokeCap = StrokeCap.round;
    if (stops > 1) canvas.drawLine(Offset(xs.first, y), Offset(reach, y), line);

    for (var i = 0; i < stops; i++) {
      final c = Offset(xs[i], y);
      final reached = stops == 1 || xs[i] <= reach + 0.5;
      if (!reached) {
        // Unreached stop sits quietly on the track (never scale 0).
        canvas.drawCircle(
          c,
          r * AppMotion.checkFrom,
          Paint()..color = AppColors.surfaceDim,
        );
        continue;
      }
      // A dot lands with a settle spring from a visible base scale.
      final span = step * HomeMetrics.routeDotSettleSpan;
      final raw = stops == 1 || progress >= 1 || span <= 0
          ? 1.0
          : ((reach - xs[i]) / span).clamp(0.0, 1.0);
      final scale =
          AppMotion.landFromScale +
          (1 - AppMotion.landFromScale) * AppMotion.settle.transform(raw);
      final dotR = r * scale;
      final ringR = (r - HomeMetrics.routeDotRing) * scale;
      for (final s in AppElevation.knob) {
        canvas.drawCircle(
          c + s.offset,
          dotR,
          Paint()
            ..color = s.color
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.blurSigma),
        );
      }
      canvas.drawCircle(c, dotR, Paint()..color = AppColors.surface);
      if (ringR > 0) {
        canvas.drawCircle(
          c,
          ringR,
          Paint()
            ..shader = const LinearGradient(
              colors: [AppColors.primaryTop, AppColors.primaryBottom],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(Rect.fromCircle(center: c, radius: dotR)),
        );
      }
    }

    // Next stop: hollow.
    canvas.drawCircle(
      Offset(end, y),
      r - HomeMetrics.routeStroke / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = HomeMetrics.routeStroke
        ..color = AppColors.onSurfaceMuted,
    );
  }

  @override
  bool shouldRepaint(_RoutePainter old) =>
      old.progress != progress || old.stops != stops || old.step != step;
}
