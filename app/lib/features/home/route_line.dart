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
import 'home_metrics.dart';

/// The trip drawn as a route: one green dot per place where money was kept,
/// joined by the green line, ending in a hollow "next stop".
class RouteLine extends StatefulWidget {
  const RouteLine({super.key, required this.stops});

  final List<RouteStop> stops;

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
          title: s.placeName ?? _kindName(l10n, s.kind),
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

    return Semantics(
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final label in labels)
                    SizedBox(
                      width: step,
                      child: Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: label,
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
              ),
            ],
          );
        },
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

    // The way ahead: a quiet track to the next stop.
    final track = Paint()
      ..color = AppColors.surfaceDim
      ..strokeWidth = HomeMetrics.routeStroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(lastStop, y), Offset(end - r, y), track);

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
      // A dot lands as the line reaches it.
      final reached = stops == 1 || xs[i] <= reach + 0.5;
      if (!reached) continue;
      final c = Offset(xs[i], y);
      for (final s in AppElevation.knob) {
        canvas.drawCircle(
          c + s.offset,
          r,
          Paint()
            ..color = s.color
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.blurSigma),
        );
      }
      canvas.drawCircle(c, r, Paint()..color = AppColors.surface);
      canvas.drawCircle(
        c,
        r - HomeMetrics.routeDotRing,
        Paint()
          ..shader = const LinearGradient(
            colors: [AppColors.primaryTop, AppColors.primaryBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
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
