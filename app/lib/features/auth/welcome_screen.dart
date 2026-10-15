import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/colors.dart';
import '../../core/spacing.dart';
import '../../core/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth/auth_failure.dart';
import '../../shared/app_button.dart';
import '../../shared/coin.dart';
import '../../shared/content_width.dart';
import '../../shared/pressable.dart';
import 'auth_brand.dart';
import 'auth_gate.dart';
import 'auth_widgets.dart';
import 'email_auth_screen.dart';

/// First launch, or after signing out: what the app does in one line, and
/// every way in. Apple first on iPhone (guideline 4.8 and HIG prominence),
/// then Google, then email; looking around needs no account.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

enum _Provider { apple, google }

class _WelcomeScreenState extends State<WelcomeScreen> {
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: ContentWidth(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenMargin,
              padding.top + AppSpacing.zoneGap,
              AppSpacing.screenMargin,
              padding.bottom + AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero zone: the coin, the promise, the reason to sign in.
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sectionHeaderInset,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const LivingCoin(),
                          const SizedBox(height: AppSpacing.zoneGap),
                          Semantics(
                            header: true,
                            child: Text(
                              l10n.authWelcomeTitle,
                              style: type.headline,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            l10n.authWelcomeBody,
                            style: type.bodyMd.copyWith(
                              color: AppColors.onSurfaceSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  AuthMessage(_error!),
                  const SizedBox(height: AppSpacing.lg),
                ],
                // Action zone. While one way in is working, the others wait.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_apple) ...[
                      AppleSignInButton(
                        label: _busy == _Provider.apple
                            ? l10n.authSigningIn
                            : l10n.authContinueApple,
                        onPressed: busy ? null : () => _signIn(_Provider.apple),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (auth.service.googleAvailable) ...[
                      GoogleSignInButton(
                        label: _busy == _Provider.google
                            ? l10n.authSigningIn
                            : l10n.authContinueGoogle,
                        onPressed: busy
                            ? null
                            : () => _signIn(_Provider.google),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    AppButton.secondary(
                      label: l10n.authContinueEmail,
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
                        child: SizedBox(
                          height: AppSizes.minTouchTarget,
                          child: Center(
                            child: Text(
                              l10n.authLookAround,
                              style: type.label.copyWith(
                                color: AppColors.onSurfaceSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
