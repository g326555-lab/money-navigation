import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/colors.dart';
import '../../core/motion.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/app_button.dart';
import 'haggle_controller.dart';

/// For a market too loud to hear: the Thai sentence and the price, as large
/// as the screen allows, for the seller to read. One tap turns the words
/// to face the seller across the stall while the meaning and the buttons
/// stay facing the traveler; only the Close button closes it.
class ShowSellerScreen extends StatefulWidget {
  const ShowSellerScreen({
    super.key,
    required this.haggle,
    required this.sentence,
    required this.amount,
    this.meaning,
  });

  final HaggleController haggle;

  /// The Thai sentence, the same one "Say it in Thai" speaks.
  final String sentence;

  /// The price as the seller reads it, e.g. "110 บาท"; null when the move
  /// has no price (walking away).
  final String? amount;

  /// The sentence in the traveler's language; null on a Thai screen.
  final String? meaning;

  @override
  State<ShowSellerScreen> createState() => _ShowSellerScreenState();
}

class _ShowSellerScreenState extends State<ShowSellerScreen> {
  bool _turned = false;

  // The screen stays on while the seller reads; a failure only means it
  // may dim as usual.
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable().catchError((Object _) {});
  }

  @override
  void dispose() {
    WakelockPlus.disable().catchError((Object _) {});
    super.dispose();
  }

  void _turn() {
    HapticFeedback.selectionClick();
    setState(() => _turned = !_turned);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final thai = AppTypography.thai;
    final type = AppTypography.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenMargin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // A dedicated close: a seller pointing at the price must
                // never dismiss it.
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: l10n.showSellerClose,
                    constraints: const BoxConstraints(
                      minWidth: AppSizes.minTouchTarget,
                      minHeight: AppSizes.minTouchTarget,
                    ),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: AppSizes.tabIcon,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                Expanded(
                  child: AnimatedRotation(
                    turns: _turned ? 0.5 : 0,
                    duration: AppMotion.of(context, AppMotion.emphasized),
                    curve: AppMotion.move,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.amount case final amount?)
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                amount,
                                maxLines: 1,
                                // Thai glyphs need room: no tight tracking,
                                // line height for Thai.
                                style: thai.displayXl.copyWith(
                                  color: AppColors.onSurface,
                                  height: thaiMinLineHeight,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            widget.sentence,
                            textAlign: TextAlign.center,
                            style: thai.headline.copyWith(
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // The meaning is for the traveler: it never turns away.
                if (widget.meaning case final meaning?) ...[
                  Text(
                    meaning,
                    textAlign: TextAlign.center,
                    style: type.bodyMd.copyWith(
                      color: AppColors.onSurfaceSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                ListenableBuilder(
                  listenable: widget.haggle,
                  builder: (context, _) {
                    final state = widget.haggle.state;
                    final turn = AppButton.secondary(
                      label: _turned
                          ? l10n.showSellerTurnBack
                          : l10n.showSellerTurn,
                      icon: Icons.screen_rotation_rounded,
                      onPressed: _turn,
                    );
                    final say = state.canSpeak
                        ? AppButton.green(
                            label: state.speaking
                                ? l10n.speakSpeaking
                                : l10n.speakSayIt,
                            icon: state.speaking
                                ? Icons.graphic_eq_rounded
                                : Icons.volume_up_rounded,
                            busy: state.speaking,
                            onPressed: () =>
                                widget.haggle.speakCounter(widget.sentence),
                          )
                        : null;
                    // The Fold cover screen is too narrow for two labels
                    // side by side: stack them there.
                    return LayoutBuilder(
                      builder: (context, constraints) =>
                          constraints.maxWidth < AppSizes.dockStackBelow
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ?say,
                                if (say != null)
                                  const SizedBox(height: AppSpacing.md),
                                turn,
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(child: turn),
                                if (say != null) ...[
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(child: say),
                                ],
                              ],
                            ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
