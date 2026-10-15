import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../core/colors.dart';
import '../../core/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth/auth_failure.dart';
import '../../shared/group.dart';
import '../../shared/pressable.dart';
import 'auth_gate.dart';
import 'auth_widgets.dart';

/// The "Account" part of Settings: who is signed in, sign out and delete
/// account; or, while looking around, a way to sign in. Drop it into the
/// Settings column; it renders nothing in a build without accounts.
class AccountSection extends StatefulWidget {
  const AccountSection({super.key, this.first = false});

  /// True when this is the first section on the page.
  final bool first;

  @override
  State<AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends State<AccountSection> {
  bool _busy = false;
  String? _error;

  Future<void> _run(Future<void> Function() action) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
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

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
    final auth = AuthScope.read(context);
    HapticFeedback.warningNotification();
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.authDeleteTitle),
        content: Text(l10n.authDeleteBody),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.authCancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.authDeleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true) await _run(auth.deleteAccount);
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    if (!auth.accountsAvailable) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final type = AppTypography.of(context);
    final link = type.link;
    final danger = type.rowTitle.copyWith(color: AppColors.errorText);

    final rows = auth.isSignedIn
        ? <Widget>[
            GroupRow(
              title: auth.profile?.displayName ?? auth.email ?? '',
              subtitle: auth.profile?.displayName == null ? null : auth.email,
            ),
            _ActionRow(
              label: l10n.authSignOut,
              style: type.rowTitle,
              onPressed: _busy ? null : () => _run(auth.signOut),
            ),
            _ActionRow(
              label: l10n.authDelete,
              style: danger,
              onPressed: _busy ? null : _confirmDelete,
            ),
          ]
        : <Widget>[
            Pressable(
              onPressed: auth.showSignIn,
              semanticLabel:
                  '${l10n.authGuestTitle}. ${l10n.authGuestSub}. ${l10n.authSignInTitle}',
              child: ExcludeSemantics(
                child: GroupRow(
                  title: l10n.authGuestTitle,
                  subtitle: l10n.authGuestSub,
                  value: l10n.authSignInTitle,
                  valueStyle: link,
                ),
              ),
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(l10n.authAccountHeader, first: widget.first),
        GroupCard(children: rows),
        AuthMessageSlot(_error),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.label,
    required this.style,
    required this.onPressed,
  });

  final String label;
  final TextStyle style;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Pressable(
    onPressed: onPressed,
    semanticLabel: label,
    child: ExcludeSemantics(
      // Muted while signing out or deleting, so the rows do not look
      // tappable while they are not.
      child: GroupRow(
        title: label,
        titleStyle: onPressed == null
            ? style.copyWith(color: AppColors.onSurfaceMuted)
            : style,
      ),
    ),
  );
}
