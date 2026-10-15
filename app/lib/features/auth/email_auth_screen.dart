import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth/account_models.dart';
import '../../services/auth/auth_failure.dart';
import '../../services/auth/auth_service.dart';
import '../../services/auth/auth_validation.dart';
import '../../shared/action_dock.dart';
import '../../shared/app_button.dart';
import '../../shared/group.dart';
import 'auth_gate.dart';
import 'auth_widgets.dart';
import 'reset_password_screen.dart';

enum _Mode { signIn, create, confirm }

/// Sign in or create an account with an email address and a password.
class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  _Mode _mode = _Mode.signIn;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  /// The first thing wrong with what was typed, or null.
  String? _check(AppLocalizations l10n) {
    final email = switch (checkEmail(_email.text)) {
      EmailProblem.empty => l10n.authErrEmailEmpty,
      EmailProblem.malformed => l10n.authErrEmailMalformed,
      null => null,
    };
    if (email != null) return email;
    // The length rule is for new passwords; an existing one is the
    // server's to judge.
    if (_mode != _Mode.create) {
      return _password.text.isEmpty ? l10n.authErrPasswordEmpty : null;
    }
    return switch (checkPassword(_password.text)) {
      PasswordProblem.empty => l10n.authErrPasswordEmpty,
      PasswordProblem.tooShort => l10n.authErrPasswordShort(minPasswordLength),
      null => null,
    };
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final problem = _check(l10n);
    if (problem != null) {
      HapticFeedback.heavyImpact();
      setState(() => _error = problem);
      return;
    }
    final service = AuthScope.read(context).service;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_mode == _Mode.create) {
        final outcome = await service.signUpWithEmail(
          email: _email.text,
          password: _password.text,
          displayName: _name.text,
        );
        if (outcome == SignUpOutcome.confirmEmail && mounted) {
          setState(() => _mode = _Mode.confirm);
        }
      } else {
        await service.signInWithEmail(
          email: _email.text,
          password: _password.text,
        );
      }
      // Signed in: the gate replaces this screen with the next step.
    } on AuthFlowException catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() => _error = failureMessage(l10n, e.failure));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _switchMode() => setState(() {
    _mode = _mode == _Mode.signIn ? _Mode.create : _Mode.signIn;
    _error = null;
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_mode == _Mode.confirm) {
      return AuthPage(
        title: l10n.authConfirmTitle,
        dock: AppButton(
          label: l10n.authBackToSignIn,
          onPressed: () => setState(() {
            _mode = _Mode.signIn;
            _password.clear();
          }),
        ),
        children: [
          AuthMessage(
            l10n.authConfirmBody(normalizeEmail(_email.text)),
            isError: false,
          ),
        ],
      );
    }
    final creating = _mode == _Mode.create;
    return AutofillGroup(
      child: AuthPage(
        title: creating ? l10n.authCreateTitle : l10n.authSignInTitle,
        // Pinned in the dock, the button rides on top of the keyboard, so
        // it is always in reach while typing.
        dock: AppButton(
          label: creating ? l10n.authCreateAction : l10n.authSignInAction,
          busy: _busy,
          onPressed: _submit,
        ),
        children: [
          GroupCard(
            children: [
              if (creating)
                AuthField(
                  label: l10n.authNameLabel,
                  controller: _name,
                  enabled: !_busy,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  maxLength: maxDisplayNameLength,
                ),
              AuthField(
                label: l10n.authEmailLabel,
                controller: _email,
                enabled: !_busy,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                onSubmitted: (_) => _passwordFocus.requestFocus(),
                onChanged: (_) => setState(() {}),
                trailing: EmailCheck(visible: checkEmail(_email.text) == null),
              ),
              AuthField(
                label: l10n.authPasswordLabel,
                controller: _password,
                focusNode: _passwordFocus,
                enabled: !_busy,
                obscure: _obscure,
                onToggleObscure: () => setState(() => _obscure = !_obscure),
                hint: creating
                    ? l10n.authPasswordRule(minPasswordLength)
                    : null,
                textInputAction: TextInputAction.done,
                autofillHints: [
                  creating ? AutofillHints.newPassword : AutofillHints.password,
                ],
                onSubmitted: (_) => _submit(),
                // The links row sits under this field, the dock under that.
                scrollBottom:
                    ActionDock.heightOf(context) + AppSizes.minTouchTarget,
              ),
            ],
          ),
          AuthMessageSlot(_error),
          const SizedBox(height: AppSpacing.sm),
          // Side by side when they fit; with large text the second link
          // moves to its own line instead of running into the first.
          Wrap(
            alignment: creating
                ? WrapAlignment.end
                : WrapAlignment.spaceBetween,
            children: [
              if (!creating)
                AuthTextLink(
                  label: l10n.authForgot,
                  onPressed: _busy
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ResetPasswordScreen(initialEmail: _email.text),
                          ),
                        ),
                ),
              AuthTextLink(
                label: creating ? l10n.authSignInAction : l10n.authCreateAction,
                emphasis: true,
                onPressed: _busy ? null : _switchMode,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
