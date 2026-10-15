import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthException, AuthState;

import 'account_models.dart';
import 'account_repository.dart';
import 'auth_failure.dart';
import 'auth_service.dart';

/// Where the app is in the account flow. [AuthGate] shows one screen per
/// stage.
enum AuthStage {
  /// Reading the stored session; nothing to show yet.
  starting,

  /// First launch or signed out: the welcome screen with the sign-in choices.
  welcome,

  /// Opened from a password reset link: signed in, new password needed.
  newPassword,

  /// Signed in, first-run questions not answered yet.
  setup,

  /// Signed in with a complete profile, or looking around without one.
  ready,
}

/// The account state the whole app reads: who is signed in, their profile,
/// and which first-run screen comes next.
class AuthController extends ChangeNotifier {
  AuthController({
    AuthService? service,
    AccountRepository? repository,
    SharedPreferencesAsync? prefs,
  }) : _service = service ?? AuthService(),
       _repo = repository ?? AccountRepository(),
       _prefs = prefs ?? SharedPreferencesAsync();

  static const _guestKey = 'auth_guest_v1';
  static const _profileKey = 'auth_profile_v1';

  final AuthService _service;
  final AccountRepository _repo;
  final SharedPreferencesAsync _prefs;
  StreamSubscription<Object?>? _sub;

  AuthStage _stage = AuthStage.starting;
  Profile? _profile;
  bool _guest = false;

  /// Opened from a reset link; nothing else opens until the new password is
  /// saved. The recovery event can arrive before or after [start] reads the
  /// session, so this flag, not the order, decides.
  bool _recovering = false;

  /// Bumped by every auth event, so a profile load that finishes after a
  /// newer event (a sign-out, another sign-in) is dropped.
  int _epoch = 0;

  AuthFailure? _notice;

  /// A failure that happened outside a screen's own action, e.g. a reset
  /// link that had expired. The welcome screen shows it once.
  AuthFailure? get notice => _notice;

  void clearNotice() => _notice = null;

  AuthStage get stage => _stage;
  AuthService get service => _service;
  AccountRepository get repository => _repo;

  /// Null while looking around without an account.
  Profile? get profile => _profile;

  /// True when the traveler chose to look around without an account, or the
  /// build has no Supabase settings.
  bool get isGuest => _guest || !_service.configured;
  bool get isSignedIn => _service.currentUser != null;
  String? get email => _service.currentUser?.email;

  /// Accounts exist in this build (it was made with env/supabase.json).
  bool get accountsAvailable => _service.configured;

  bool _started = false;

  /// Reads the stored session once; later calls do nothing. Never notifies
  /// synchronously, so it is safe to call from initState.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    if (!_service.configured) {
      await Future<void>.value();
      _set(AuthStage.ready);
      return;
    }
    _guest = await _read<bool?>(() => _prefs.getBool(_guestKey)) ?? false;
    _sub = _service.changes.listen(_onEvent, onError: _onStreamError);
    if (_service.currentUser != null) {
      await _afterSignIn();
    } else {
      _set(_guest ? AuthStage.ready : AuthStage.welcome);
    }
  }

  void _onEvent(AuthState state) {
    switch (state.event) {
      case AuthChangeEvent.signedIn ||
          AuthChangeEvent.signedOut ||
          AuthChangeEvent.passwordRecovery:
        _epoch++;
      default:
        break;
    }
    switch (state.event) {
      case AuthChangeEvent.signedIn:
        _notice = null;
        if (_stage != AuthStage.starting && !_recovering) {
          unawaited(_afterSignIn());
        }
      case AuthChangeEvent.passwordRecovery:
        _recovering = true;
        _set(AuthStage.newPassword);
      case AuthChangeEvent.signedOut:
        _recovering = false;
        _profile = null;
        unawaited(_forget());
        _set(_guest ? AuthStage.ready : AuthStage.welcome);
      default:
        break;
    }
  }

  /// supabase_flutter reports a link it could not use (expired, opened on
  /// another phone) as an error on the auth stream.
  ///
  /// While signed in such an error (e.g. a token refresh that failed
  /// offline) changes nothing: the session is still there and the next
  /// refresh retries. Only an error with no session is shown, once, on the
  /// welcome screen.
  void _onStreamError(Object error) {
    if (_service.currentUser != null) return;
    _epoch++;
    var notice = error is AuthException
        ? classifyAuthError(code: error.code, message: error.message)
        : AuthFailure.codeInvalid;
    if (notice == AuthFailure.unknown) notice = AuthFailure.codeInvalid;
    _notice = notice;
    _recovering = false;
    _set(_guest ? AuthStage.ready : AuthStage.welcome);
  }

  /// Reads the profile again, e.g. after Apple sent the traveler's name.
  Future<void> refreshProfile() async {
    if (_service.currentUser != null) await _afterSignIn();
  }

  /// "Look around without an account": the app opens with the device-only
  /// stores and does not ask again on the next launch.
  Future<void> continueAsGuest() async {
    _guest = true;
    _set(AuthStage.ready);
    await _read(() => _prefs.setBool(_guestKey, true));
  }

  /// From Settings while looking around: back to the sign-in choices.
  void showSignIn() => _set(AuthStage.welcome);

  /// After a reset link: saves the new password, then opens the app.
  Future<void> setNewPassword(String password) async {
    await _service.setNewPassword(password);
    _recovering = false;
    await _afterSignIn();
  }

  Future<void> completeSetup(ProfileDraft draft) async {
    final saved = await _repo.saveSetup(draft, now: DateTime.now());
    _profile = saved;
    await _remember(saved);
    _set(AuthStage.ready);
  }

  Future<void> signOut() async {
    _guest = false;
    await _read(() => _prefs.setBool(_guestKey, false));
    await _service.signOut();
  }

  Future<void> deleteAccount() async {
    _guest = false;
    await _read(() => _prefs.setBool(_guestKey, false));
    await _service.deleteAccount();
    _profile = null;
    await _forget();
    _set(AuthStage.welcome);
  }

  Future<void> _afterSignIn() async {
    final epoch = _epoch;
    if (_recovering) {
      _set(AuthStage.newPassword);
      return;
    }
    _guest = false;
    unawaited(_read(() => _prefs.setBool(_guestKey, false)));
    Profile? profile;
    var fresh = false;
    try {
      profile = await _repo.loadProfile();
      fresh = profile != null;
    } on Object catch (e) {
      debugPrint('AuthController: profile load failed: $e');
      // Offline at launch: use the profile from the last good load so a
      // signed-in traveler is never locked out of their own app.
      profile = await _remembered();
    }
    // A newer event (sign-out, another account) owns the stage now; at
    // launch nothing else would set one, so read again.
    if (epoch != _epoch) return _settleIfStarting();
    if (_service.currentUser == null) {
      _set(_guest ? AuthStage.ready : AuthStage.welcome);
      return;
    }
    // Cache only now: a load overtaken by a sign-out must not write back
    // the profile the sign-out just cleared.
    if (fresh) await _remember(profile!);
    if (epoch != _epoch) return _settleIfStarting();
    _profile = profile;
    // A reset link may have opened while the profile loaded; it wins.
    if (_recovering) {
      _set(AuthStage.newPassword);
      return;
    }
    // Unknown (offline, never loaded) counts as ready: asking the first-run
    // questions again would overwrite answers we just could not read.
    _set(
      profile == null || profile.isComplete ? AuthStage.ready : AuthStage.setup,
    );
  }

  /// Called when a load was overtaken. Events ignored during [AuthStage.starting]
  /// would otherwise leave the launch page up for good.
  Future<void> _settleIfStarting() async {
    if (_stage != AuthStage.starting) return;
    if (_service.currentUser != null) {
      await _afterSignIn();
    } else {
      _set(_guest ? AuthStage.ready : AuthStage.welcome);
    }
  }

  Future<void> _remember(Profile p) => _read(
    () => _prefs.setString(
      _profileKey,
      jsonEncode({'id': p.id, ...p.toSetupRow()}),
    ),
  );

  Future<Profile?> _remembered() async {
    final raw = await _read(() => _prefs.getString(_profileKey));
    if (raw == null) return null;
    try {
      final p = Profile.fromRow(jsonDecode(raw));
      return p?.id == _service.currentUser?.id ? p : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> _forget() => _read(() => _prefs.remove(_profileKey));

  /// Preferences can fail on a broken store; the flow must not.
  Future<T?> _read<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on Object {
      return null;
    }
  }

  void _set(AuthStage stage) {
    _stage = stage;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
