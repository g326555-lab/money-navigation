import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/colors.dart';
import '../../core/elevation.dart';
import '../../core/formatters.dart';
import '../../core/motion.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth/auth_failure.dart';
import '../../shared/app_button.dart';
import '../../shared/coin.dart';
import '../../shared/content_width.dart';
import '../../shared/pressable.dart';
import '../../shared/surface.dart';
import 'auth_brand.dart';
import 'auth_gate.dart';
import 'auth_widgets.dart';
import 'email_auth_screen.dart';
import 'welcome_example.dart';

/// First launch, or after signing out. The hero shows what the app does
/// with a real result (the printed ATM prop through the scanner's rule,
/// labelled as an example); below it every way in, one group of equal
/// buttons: Apple first on iPhone (guideline 4.8, HIG prominence), Google,
/// then email. Looking around needs no account.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

enum _Provider { apple, google }

class _WelcomeScreenState extends State<WelcomeScreen> {
  /// Shares of the spare height above and below the hero.
  static const _heroSpaceAbove = 2;
  static const _heroSpaceBelow = 3;

  bool _apple = false;
  _Provider? _busy;
  String? _error;

  @override
  void initState() {
    super.initState();
    final auth = AuthScope.read(context);
    auth.service.appleAvailable().then((available) {
      if (mounted && available) setState(() => _apple = true);
    });
    // A reset link that could not be used brings the traveler back here.
    final notice = auth.notice;
    if (notice != null) {
      auth.clearNotice();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(
          () => _error = failureMessage(AppLocalizations.of(context), notice),
        );
      });
    }
  }

  Future<void> _signIn(_Provider provider) async {
    final auth = AuthScope.read(context);
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = provider;
      _error = null;
    });
    try {
      switch (provider) {
        case _Provider.apple:
          await auth.service.signInWithApple();
          // Apple sends the name after the sign-in event read the profile.
          await auth.refreshProfile();
        case _Provider.google:
          await auth.service.signInWithGoogle();
      }
      // The gate opens the next screen from the sign-in event.
    } on AuthFlowException catch (e) {
      if (!mounted) return;
      final message = failureMessage(l10n, e.failure);
      if (message != null) HapticFeedback.heavyImpact();
      setState(() => _error = message);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final auth = AuthScope.of(context);
    final padding = MediaQuery.paddingOf(context);
    final busy = _busy != null;
    // The page measures its height intrinsically, so the text is balanced
    // against the known width rather than a measured one.
    final textWidth =
        math.min(MediaQuery.sizeOf(context).width, AppSizes.contentMaxWidth) -
        AppSpacing.screenMargin * 2 -
        AppSpacing.sectionHeaderInset * 2;
    final lookAroundColor = busy
        ? AppColors.onSurfaceMuted
        : AppColors.onSurfaceSecondary;

    final hero = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ExampleCard(
          textWidth:
              textWidth +
              (AppSpacing.sectionHeaderInset - AppSpacing.heroCardPadding) * 2,
        ),
        const SizedBox(height: AppSpacing.zoneGap),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sectionHeaderInset,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: BalancedText(
                  l10n.authWelcomeTitle,
                  style: type.headline,
                  maxWidth: textWidth,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              BalancedText(
                l10n.authWelcomeBody,
                style: type.heroLabel,
                maxWidth: textWidth,
              ),
            ],
          ),
        ),
      ],
    );

    // While one way in is working, the others wait.
    final actions = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The message sits above the ways in, with the group gap below it.
        AuthMessageSlot(_error),
        AnimatedSize(
          duration: AppMotion.of(context, AppMotion.standard),
          curve: AppMotion.move,
          child: SizedBox(height: _error == null ? 0 : AppSpacing.lg),
        ),
        if (_apple) ...[
          AppleSignInButton(
            label: _busy == _Provider.apple
                ? l10n.authSigningIn
                : l10n.authContinueApple,
            busy: _busy == _Provider.apple,
            onPressed: busy ? null : () => _signIn(_Provider.apple),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (auth.service.googleAvailable) ...[
          GoogleSignInButton(
            label: _busy == _Provider.google
                ? l10n.authSigningIn
                : l10n.authContinueGoogle,
            busy: _busy == _Provider.google,
            onPressed: busy ? null : () => _signIn(_Provider.google),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AppButton.secondary(
          label: l10n.authContinueEmail,
          icon: Icons.mail_outline_rounded,
          onPressed: busy
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const EmailAuthScreen(),
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Pressable(
          onPressed: busy ? null : auth.continueAsGuest,
          semanticLabel: l10n.authLookAround,
          child: ExcludeSemantics(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSizes.minTouchTarget,
              ),
              // The arrow rides inline after the last word, so with large
              // text the line wraps centred and the arrow stays with it.
              child: Center(
                child: Text.rich(
                  TextSpan(
                    text: l10n.authLookAround,
                    children: [
                      // A no-break space glues the arrow to the last word.
                      const TextSpan(text: '\u00A0'),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: AppSizes.buttonIcon,
                          color: lookAroundColor,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: type.label.copyWith(color: lookAroundColor),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            ContentWidth(
              // Hero at the top, the ways in at the bottom; on a short screen
              // (the Fold cover) the whole page scrolls instead of squeezing.
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenMargin,
                    padding.top + AppSpacing.lg,
                    AppSpacing.screenMargin,
                    padding.bottom + AppSpacing.lg,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          constraints.maxHeight -
                          padding.top -
                          padding.bottom -
                          AppSpacing.lg * 2,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // DESIGN.md: the action zone sits at the bottom, in
                          // thumb reach. On a tall screen the spare height is
                          // shared, two fifths above the hero and three fifths
                          // below it, so the hero sits in the upper part of
                          // the page instead of leaving one wide hole above
                          // the buttons. On short screens both collapse.
                          const Spacer(flex: _heroSpaceAbove),
                          hero,
                          const Spacer(flex: _heroSpaceBelow),
                          const SizedBox(height: AppSpacing.zoneGap),
                          actions,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // The page scrolls on short screens; keep the clock legible.
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: padding.top,
              child: const ColoredBox(color: AppColors.background),
            ),
          ],
        ),
      ),
    );
  }
}

/// The hero card: the coin, what the ATM offered, and what declining kept.
class _ExampleCard extends StatelessWidget {
  const _ExampleCard({required this.textWidth});

  /// Width of the card's text column, for balancing the label.
  final double textWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final kept = AppFormat.roundedAmount(welcomeExampleKeptThb(), 'THB');
    return Semantics(
      container: true,
      label: l10n.authWelcomeExampleSemantics(kept),
      excludeSemantics: true,
      child: Surface(
        radius: AppRadius.xl,
        padding: const EdgeInsets.all(AppSpacing.heroCardPadding),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryContainer, AppColors.primaryContainerEnd],
        ),
        shadows: AppElevation.e1Green,
        edgeLight: EdgeLights.onTile,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Coin(size: AuthSizes.welcomeCoin),
                const Spacer(),
                // A quiet tag, not a badge: the card is an example, not your result.
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _Dot(),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      l10n.authWelcomeExample,
                      style: type.caption.copyWith(
                        color: AppColors.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            BalancedText(
              l10n.authWelcomeExampleLabel,
              style: type.heroLabel.copyWith(
                color: AppColors.onPrimaryContainer,
              ),
              maxWidth: textWidth,
            ),
            const SizedBox(height: AppSpacing.xs),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(kept, style: type.displayLg),
            ),
            const SizedBox(height: AppSpacing.md),
            _Chip(
              label: l10n.authWelcomeExampleChip,
              // As tall as the label's line, so mark and words read as one.
              leading: Icon(
                Icons.check_circle_outline_rounded,
                size: type.label.fontSize! * type.label.height!,
                color: AppColors.primaryText,
              ),
              strong: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.leading,
    this.strong = false,
  });

  final String label;
  final Widget leading;

  /// The result chip reads stronger; the "Example" tag stays quiet.
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final type = AppTypography.of(context);
    return DecoratedBox(
      decoration: const ShapeDecoration(
        shape: StadiumBorder(),
        color: AppColors.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.chipPadding,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(width: AppSpacing.sm),
            // One line always; a long translation shrinks instead of
            // wrapping inside the capsule.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  maxLines: 1,
                  style: (strong ? type.label : type.caption).copyWith(
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: ShapeDecoration(
      shape: CircleBorder(),
      color: AppColors.primary,
    ),
    child: SizedBox.square(dimension: AuthSizes.tagDot),
  );
}
