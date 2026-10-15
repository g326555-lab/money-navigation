import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/elevation.dart';
import '../../core/formatters.dart';
import '../../core/motion.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/atm_conversion.dart';
import 'scan_controller.dart';

/// White sheet listing the real steps of a scan as they finish.
class ScanStepsSheet extends StatelessWidget {
  const ScanStepsSheet({super.key, required this.state, required this.onRetry});

  final ScanState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final failure = state.failure;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
        boxShadow: AppElevation.e2Sheet,
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
          if (failure != null) ...[
            Text(
              _tip(l10n, failure),
              style: type.bodyMd.copyWith(color: AppColors.onSurfaceSecondary),
            ),
            const SizedBox(height: AppSpacing.xxl),
            FilledButton(onPressed: onRetry, child: Text(l10n.scanTryAgain)),
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
      case ScanStepId.compare:
        final v = state.verdict;
        if (v == null) return l10n.stepCompare;
        return v.extraCostThb.round() > 0
            ? l10n.stepCompareDone(
                AppFormat.roundedAmount(v.extraCostThb, atmLocalCurrency),
              )
            : l10n.stepCompareEven;
    }
  }

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
            color: AppColors.onSurfaceMuted,
          ),
        );
      case ScanStepState.done:
        return const DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            size: AppSizes.stepGlyph,
            color: AppColors.onPrimary,
          ),
        );
      case ScanStepState.failed:
        return const DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.errorContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.priority_high_rounded,
            size: AppSizes.stepGlyph,
            color: AppColors.errorText,
          ),
        );
    }
  }
}
