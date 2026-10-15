import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/motion.dart';
import '../../services/auth/auth_controller.dart';
import 'profile_setup_screen.dart';
import 'reset_password_screen.dart';
import 'welcome_screen.dart';

/// Gives every screen below it the [AuthController].
class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required AuthController controller,
    required super.child,
  }) : super(notifier: controller);

  static AuthController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>()!.notifier!;

  /// For callbacks that must not rebuild when the account changes.
  static AuthController read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AuthScope>()!.notifier!;
}

/// Shows the welcome screen, the first-run questions or the app, depending
/// on the account. Put it at `MaterialApp.home` with the app shell as
/// [child]:
///
/// ```dart
/// home: AuthGate(controller: _auth, child: const AppShell()),
/// ```
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.controller, required this.child});

  final AuthController controller;

  /// The app itself, shown when signed in with a complete profile or when
  /// looking around without an account.
  final Widget child;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late AuthStage _shown = widget.controller.stage;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
    if (widget.controller.stage == AuthStage.starting) {
      widget.controller.start();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  /// A new stage replaces whatever was pushed on top (the email screen after
  /// signing in, Settings after signing out), so the gate's page is visible.
  void _onChange() {
    final stage = widget.controller.stage;
    if (stage == _shown) return;
    _shown = stage;
    Navigator.maybeOf(context)?.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      controller: widget.controller,
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final stage = widget.controller.stage;
          final Widget page = switch (stage) {
            // The stored session is read in a few milliseconds; a plain page
            // in the launch colour avoids a flash of the welcome screen.
            AuthStage.starting => const ColoredBox(
              color: AppColors.background,
              child: SizedBox.expand(),
            ),
            AuthStage.welcome => const WelcomeScreen(),
            AuthStage.newPassword => const NewPasswordScreen(),
            AuthStage.setup => const ProfileSetupScreen(),
            AuthStage.ready => widget.child,
          };
          return AnimatedSwitcher(
            duration: AppMotion.of(context, AppMotion.standard),
            switchInCurve: AppMotion.enter,
            switchOutCurve: AppMotion.exit,
            child: KeyedSubtree(key: ValueKey(stage), child: page),
          );
        },
      ),
    );
  }
}
