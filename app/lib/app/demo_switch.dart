import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/colors.dart';
import '../core/motion.dart';
import '../core/spacing.dart';
import '../core/typography.dart';
import '../l10n/app_localizations.dart';
import '../rules/demo_personas.dart';
import 'app_scope.dart';

/// The demo persona's name in the reader's language.
String demoPersonaName(AppLocalizations l10n, DemoPersona persona) =>
    switch (persona.key) {
      'visitorBangkok' => l10n.demoVisitorBangkok,
      'thaiTokyo' => l10n.demoThaiTokyo,
      final key => key,
    };

/// "English · USD": the language and currency a persona brings.
String demoPersonaDetail(AppLocalizations l10n, DemoPersona persona) =>
    l10n.demoPersonaDetail(
      persona.language == 'th' ? l10n.authLanguageTh : l10n.authLanguageEn,
      persona.homeCurrency,
    );

/// Runs the demo switch for the whole app. Sits in MaterialApp.builder, so
/// it covers every route while language, currency and sample records
/// change together under one curtain.
class DemoSwitch extends StatefulWidget {
  const DemoSwitch({super.key, required this.child});

  final Widget child;

  /// Switches to [persona], or out of the demo state when null.
  /// Without a [DemoSwitch] above (previews, tests) it switches at once.
  static Future<void> to(BuildContext context, DemoPersona? persona) {
    final state = context.findAncestorStateOfType<_DemoSwitchState>();
    if (state != null) return state._to(persona);
    return _apply(AppScope.of(context), persona);
  }

  static Future<void> _apply(AppScope scope, DemoPersona? persona) async {
    // Coming into the demo from normal use: both demo states start again
    // from their samples.
    if (!scope.settings.demoState) {
      await (
        scope.trip.resetDemo(),
        scope.receipts.resetDemo(),
        scope.cashWallet.resetDemo(),
      ).wait;
    }
    // One notification: the app changes language, currency and records in
    // the same frame.
    await scope.settings.setDemoPersona(persona);
  }

  @override
  State<DemoSwitch> createState() => _DemoSwitchState();
}

class _DemoSwitchState extends State<DemoSwitch> with TickerProviderStateMixin {
  late final _curtain = AnimationController(
    vsync: this,
    duration: AppMotion.demoCurtainIn,
    reverseDuration: AppMotion.demoCurtainOut,
  );
  late final _name = AnimationController(
    vsync: this,
    duration: AppMotion.demoNameIn,
  );
  bool _busy = false;

  @override
  void dispose() {
    _curtain.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _to(DemoPersona? persona) async {
    final scope = AppScope.of(context);
    final settings = scope.settings;
    if (_busy || settings.demoPersona?.key == persona?.key) return;
    _busy = true;
    try {
      final animate = !MediaQuery.disableAnimationsOf(context);
      if (animate) await _curtain.forward(from: 0);
      HapticFeedback.mediumImpact();
      await DemoSwitch._apply(scope, persona);
      if (!animate || !mounted) return;
      if (persona != null) {
        await _name.forward(from: 0);
        await Future<void>.delayed(AppMotion.demoNameHold);
      }
      if (!mounted) return;
      await _curtain.reverse();
      _name.value = 0;
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    return Stack(
      children: [
        widget.child,
        AnimatedBuilder(
          animation: _curtain,
          builder: (context, child) => _curtain.value == 0
              ? const SizedBox.shrink()
              : Positioned.fill(
                  child: AbsorbPointer(
                    child: FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _curtain,
                        curve: AppMotion.move,
                      ),
                      child: child,
                    ),
                  ),
                ),
          // Material: text on the curtain sits above the Navigator, outside
          // any page's Material.
          child: Material(
            color: AppColors.background,
            child: ListenableBuilder(
              listenable: settings,
              builder: (context, _) => switch (settings.demoPersona) {
                null => const SizedBox.expand(),
                final persona => _PersonaName(
                  persona: persona,
                  progress: _name,
                ),
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// The traveler the demo just switched to, rising into place on the
/// curtain in their own language.
class _PersonaName extends StatelessWidget {
  const _PersonaName({required this.persona, required this.progress});

  final DemoPersona persona;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final curved = CurvedAnimation(parent: progress, curve: AppMotion.enter);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenMargin,
        ),
        child: FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(
              begin: AppMotion.demoNameRise,
              end: Offset.zero,
            ).animate(curved),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.demoLabel,
                  style: type.label.copyWith(
                    color: AppColors.onSurfaceTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  demoPersonaName(l10n, persona),
                  textAlign: TextAlign.center,
                  style: type.headline,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  demoPersonaDetail(l10n, persona),
                  style: type.bodyMd.copyWith(
                    color: AppColors.onSurfaceSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
