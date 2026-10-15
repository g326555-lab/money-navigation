import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth/auth_failure.dart';
import '../../services/auth/auth_validation.dart';
import '../../shared/app_button.dart';
import '../../shared/group.dart';
import 'auth_gate.dart';
import 'auth_widgets.dart';

/// Forgot password: Supabase emails a link that opens the app, which then
/// asks for the new password ([NewPasswordScreen]).
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late final _email = TextEditingController(text: widget.initialEmail.trim());
  bool _sent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final problem = switch (checkEmail(_email.text)) {
      EmailProblem.empty => l10n.authErrEmailEmpty,
      EmailProblem.malformed => l10n.authErrEmailMalformed,
      null => null,
    };
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
      await service.sendPasswordResetLink(_email.text);
      if (mounted) setState(() => _sent = true);
    } on AuthFlowException catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(
        () => _error = failureMessage(l10n, e.failure, signingIn: false),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AuthPage(
      title: l10n.authResetTitle,
      dock: _sent
          ? AppButton(
              label: l10n.authBackToSignIn,
              onPressed: () => Navigator.of(context).pop(),
            )
          : AppButton(label: l10n.authResetSend, busy: _busy, onPressed: _send),
      children: [
        GroupCard(
          children: [
            AuthField(
              label: l10n.authEmailLabel,
              controller: _email,
              enabled: !_busy && !_sent,
              autofocus: _email.text.isEmpty,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.send,
              autofillHints: const [AutofillHints.email],
              onSubmitted: (_) => _send(),
            ),
          ],
        ),
        if (_error != null)
          AuthMessage(_error!)
        else
          AuthMessage(
            _sent
                ? l10n.authResetSentTo(normalizeEmail(_email.text))
                : l10n.authResetIntro,
            isError: false,
          ),
        if (_sent) ...[
          const SizedBox(height: AppSpacing.groupGap),
          AuthTextLink(
            label: l10n.authResetResend,
            onPressed: _busy ? null : _send,
          ),
        ],
      ],
    );
  }
}

/// Opened from the reset link: the traveler is signed in for this one step
/// and sets a new password; the app opens after it is saved.
class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final problem = switch (checkPassword(_password.text)) {
      PasswordProblem.empty => l10n.authErrPasswordEmpty,
      PasswordProblem.tooShort => l10n.authErrPasswordShort(minPasswordLength),
      null => null,
    };
    if (problem != null) {
      HapticFeedback.heavyImpact();
      setState(() => _error = problem);
      return;
    }
    final auth = AuthScope.read(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await auth.setNewPassword(_password.text);
    } on AuthFlowException catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(
        () => _error = failureMessage(l10n, e.failure, signingIn: false),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AutofillGroup(
      child: AuthPage(
        title: l10n.authNewPasswordTitle,
        showBack: false,
        dock: AppButton(
          label: l10n.authResetSave,
          busy: _busy,
          onPressed: _save,
        ),
        children: [
          GroupCard(
            children: [
              AuthField(
                label: l10n.authResetNewPassword,
                controller: _password,
                enabled: !_busy,
                autofocus: true,
                obscure: _obscure,
                onToggleObscure: () => setState(() => _obscure = !_obscure),
                hint: l10n.authPasswordRule(minPasswordLength),
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onSubmitted: (_) => _save(),
              ),
            ],
          ),
          if (_error != null) AuthMessage(_error!),
        ],
      ),
    );
  }
}
