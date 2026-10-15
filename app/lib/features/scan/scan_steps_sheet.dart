import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/elevation.dart';
import '../../core/formatters.dart';
import '../../core/motion.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/atm_conversion.dart';
import '../../shared/app_button.dart';
import 'scan_controller.dart';

import 'package:intl/intl.dart';

import '../../services/ai/photo_kind_classifier.dart';
import '../../shared/action_dock.dart';

/// White sheet listing the real steps of a scan as they finish.
class ScanStepsSheet extends StatelessWidget {
  const ScanStepsSheet({
    super.key,
    required this.state,
    required this.onRetry,
    this.onCheckBill,
  });

  final ScanState state;
  final VoidCallback onRetry;

  /// Offered when the photo was not a payment screen but the on-device
  /// model sees a bill or menu.
  final VoidCallback? onCheckBill;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final failure = state.failure;
    return Container(
      width: double.infinity,
      decoration: ShapeDecoration(
        color: AppColors.surface,
        shape: const RoundedSuperellipseBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        shadows: AppElevation.e2Sheet,
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sheetPadding,
        AppSpacing.md,
        AppSpacing.sheetPadding,
        AppSpacing.sheetPadding + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: AppSizes.sheetHandleWidth,
              height: AppSizes.sheetHandleHeight,
              decoration: BoxDecoration(
                color: AppColors.handle,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          for (final step in state.steps)
            _StepRow(
              key: ValueKey(step.id),
              step: step,
              text: _stepText(l10n, step),
            ),
          if (state.kindGuess case (final kind, final confidence, final trace))
            Padding(
              padding: const EdgeInsets.only(
                left: AppSizes.stepIcon + AppSpacing.md,
                bottom: AppSpacing.md,
              ),
              child: Text(
                l10n.scanKindLine(
                  trace.engine.displayName,
                  _kindName(l10n, kind),
                  NumberFormat.percentPattern('en').format(confidence),
                  trace.elapsedLabel,
                ),
                style: type.footer,
              ),
            ),
          if (failure != null) ...[
            // Aligned with the step text, under the step that failed.
            Padding(
              padding: const EdgeInsets.only(
                left: AppSizes.stepIcon + AppSpacing.md,
              ),
              child: Text(
                _tip(l10n, failure),
                style: type.bodyMd.copyWith(
                  color: AppColors.onSurfaceSecondary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            if (onCheckBill != null &&
                state.kindGuess?.$1 == PhotoKind.receiptMenu)
              DockPair(
                secondaryLabel: l10n.scanTryAgain,
                onSecondary: onRetry,
                primaryLabel: l10n.scanCheckAsBill,
                onPrimary: onCheckBill,
              )
            else
              AppButton(label: l10n.scanTryAgain, onPressed: onRetry),
          ],
        ],
      ),
    );
  }

  String _stepText(AppLocalizations l10n, ScanStep step) {
    final done = step.state == ScanStepState.done;
    final failed = step.state == ScanStepState.failed;
    switch (step.id) {
      case ScanStepId.readText:
        final ms = state.readElapsed?.inMilliseconds;
        if (failed) return l10n.stepReadTextFailed;
        return done && ms != null
            ? l10n.stepReadTextDone(ms)
            : l10n.stepReadText;
      case ScanStepId.findAtm:
        if (failed) return l10n.stepFindAtmFailed;
        return done ? l10n.stepFindAtmDone : l10n.stepFindAtm;
      case ScanStepId.readValues:
        final r = state.reading;
        if (failed || r == null) return l10n.stepValuesFailed;
        final values = l10n.stepValues(
          AppFormat.amount(r.withdrawalThb, atmLocalCurrency),
          AppFormat.amount(r.accessFeeThb, atmLocalCurrency),
          AppFormat.rate(r.thbPerUsd),
        );
        final markup = r.markupPercent;
        return markup == null
            ? values
            : l10n.stepValuesMarkup(values, AppFormat.percent(markup));
      case ScanStepId.findTerminal:
        return l10n.stepFindTerminalDone;
      case ScanStepId.findBoard:
        return l10n.stepFindBoardDone;
      case ScanStepId.compare:
        if (state.dcc case final d?) {
          return l10n.stepCompareDcc(
            AppFormat.roundedAmount(d.extraHome, d.rate.base),
          );
        }
        if (state.board case final b?) {
          return l10n.stepCompareBoard(
            AppFormat.roundedPercent(b.sellLossPercent),
          );
        }
        final v = state.verdict;
        if (v == null) return l10n.stepCompare;
        return v.extraCostThb.round() > 0
            ? l10n.stepCompareDone(
                AppFormat.roundedAmount(v.extraCostThb, atmLocalCurrency),
              )
            : l10n.stepCompareEven;
    }
  }

  static String _kindName(AppLocalizations l10n, PhotoKind kind) =>
      switch (kind) {
        PhotoKind.atm => l10n.kindAtm,
        PhotoKind.cardTerminal => l10n.kindTerminal,
        PhotoKind.receiptMenu => l10n.kindBill,
        PhotoKind.priceTag => l10n.kindPriceTag,
        PhotoKind.other => l10n.kindOther,
      };

  String _tip(AppLocalizations l10n, ScanFailure failure) => switch (failure) {
    ScanFailure.noText => l10n.scanTipNoText,
    ScanFailure.notAtm => l10n.scanTipNotAtm,
    ScanFailure.missingValues => l10n.scanTipMissingValues,
  };
}

class _StepRow extends StatefulWidget {
  const _StepRow({super.key, required this.step, required this.text});

  final ScanStep step;
  final String text;

  @override
  State<_StepRow> createState() => _StepRowState();
}

class _StepRowState extends State<_StepRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: AppMotion.standard,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _enter.duration = AppMotion.of(context, AppMotion.standard);
    if (!_enter.isAnimating && _enter.value == 0) _enter.forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = AppTypography.of(context);
    final curved = CurvedAnimation(parent: _enter, curve: AppMotion.enter);
    final color = switch (widget.step.state) {
      ScanStepState.running => AppColors.onSurfaceTertiary,
      ScanStepState.done => AppColors.onSurface,
      ScanStepState.failed => AppColors.errorText,
    };
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: AppMotion.stepRise,
          end: Offset.zero,
        ).animate(curved),
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox.square(
                dimension: AppSizes.stepIcon,
                child: AnimatedSwitcher(
                  duration: AppMotion.of(context, AppMotion.quick),
                  child: _StepIcon(
                    key: ValueKey(widget.step.state),
                    state: widget.step.state,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: AppMotion.of(context, AppMotion.quick),
                  style: type.bodyMd.copyWith(color: color),
                  child: Text(widget.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepIcon extends StatelessWidget {
  const _StepIcon({super.key, required this.state});

  final ScanStepState state;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case ScanStepState.running:
        return const Padding(
          padding: EdgeInsets.all(AppSpacing.xs),
          child: CircularProgressIndicator(
            strokeWidth: AppSizes.progressStroke,
            strokeCap: StrokeCap.round,
            color: AppColors.onSurfaceMuted,
          ),
        );
      case ScanStepState.done:
        return const _StepBadge(
          fill: AppColors.primary,
          ink: AppColors.onPrimary,
          glyph: _Glyph.check,
        );
      case ScanStepState.failed:
        return const _StepBadge(
          fill: AppColors.errorContainer,
          ink: AppColors.errorText,
          glyph: _Glyph.mark,
        );
    }
  }
}

enum _Glyph { check, mark }

/// A finished step's badge: the disc lands with a slight overshoot, then
/// its glyph draws itself, so each check reads as "this just finished".
class _StepBadge extends StatefulWidget {
  const _StepBadge({
    required this.fill,
    required this.ink,
    required this.glyph,
  });

  final Color fill;
  final Color ink;
  final _Glyph glyph;

  @override
  State<_StepBadge> createState() => _StepBadgeState();
}

class _StepBadgeState extends State<_StepBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.standard,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _c.duration = AppMotion.of(context, AppMotion.standard);
    if (_c.value == 0 && !_c.isAnimating) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Disc in the first 60 %, glyph stroke from 35 % to the end.
    final disc = CurvedAnimation(
      parent: _c,
      curve: const Interval(0, 0.6, curve: AppMotion.settle),
    );
    final stroke = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.35, 1, curve: AppMotion.enter),
    );
    return ScaleTransition(
      scale: disc,
      child: DecoratedBox(
        decoration: BoxDecoration(color: widget.fill, shape: BoxShape.circle),
        child: AnimatedBuilder(
          animation: stroke,
          builder: (_, _) => CustomPaint(
            size: const Size.square(AppSizes.stepIcon),
            painter: _GlyphPainter(widget.glyph, widget.ink, stroke.value),
          ),
        ),
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.glyph, this.color, this.progress);

  final _Glyph glyph;
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final w = size.width;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppSizes.progressStroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // Drawn on a 24 grid so the glyph matches the 24 icon set's proportions.
    final u = w / AppSizes.stepIcon;
    final path = switch (glyph) {
      _Glyph.check =>
        Path()
          ..moveTo(7.5 * u, 12.5 * u)
          ..lineTo(10.5 * u, 15.5 * u)
          ..lineTo(16.5 * u, 9 * u),
      _Glyph.mark =>
        Path()
          ..moveTo(12 * u, 7.5 * u)
          ..lineTo(12 * u, 13 * u),
    };
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
    }
    if (glyph == _Glyph.mark && progress >= 1) {
      canvas.drawCircle(
        Offset(12 * u, 16.5 * u),
        AppSizes.progressStroke * 0.6,
        paint..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.progress != progress || old.color != color || old.glyph != glyph;
}
