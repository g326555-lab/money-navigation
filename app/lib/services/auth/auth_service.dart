import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_failure.dart';
import 'auth_validation.dart';
import 'nonce.dart';

/// Build-time settings, passed with `--dart-define-from-file=env/supabase.json`.
/// Client IDs are public identifiers, not secrets.
abstract final class AuthConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Google Cloud "Web application" OAuth client: the audience of the ID
  /// token Supabase verifies (`serverClientId`).
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  /// Google Cloud "iOS" OAuth client for com.hyunjunkim.moneyNavigation.
  static const googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );

  /// The app's own link, allowed in Supabase Auth > URL configuration and
  /// registered as a URL scheme on iOS and an intent filter on Android.
  static const redirectUrl = 'com.hyunjunkim.moneynavigation://auth-callback';

  static bool get supabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get googleConfigured =>
      googleWebClientId.isNotEmpty &&
      (defaultTargetPlatform != TargetPlatform.iOS ||
          googleIosClientId.isNotEmpty);
}

/// Starts Supabase once, before the first frame. Does nothing in a build made
/// without the env file; the app then runs without accounts.
Future<void> initSupabase() async {
  if (!AuthConfig.supabaseConfigured) return;
  await Supabase.initialize(
    url: AuthConfig.supabaseUrl,
    publishableKey: AuthConfig.supabaseAnonKey,
  );
}

/// What finishing an email sign-up led to.
enum SignUpOutcome {
  /// The account exists and the traveler is signed in.
  signedIn,

  /// The project asks for a confirmed address first; a link was emailed.
  confirmEmail,
}

/// Every way to get into an account, behind one class that throws only
/// [AuthFlowException], so screens have one thing to catch and explain.
///
/// Google and Apple both run natively and hand their ID token to Supabase
/// (`signInWithIdToken`), as the Supabase Flutter guides describe:
/// https://supabase.com/docs/guides/auth/social-login/auth-google?platform=flutter
/// https://supabase.com/docs/guides/auth/social-login/auth-apple?platform=flutter
class AuthService {
  AuthService();

  GoTrueClient get _auth => Supabase.instance.client.auth;

  bool get configured => AuthConfig.supabaseConfigured;

  /// The anonymous session the app opens for cloud calls is not an account,
  /// so it reads as signed out everywhere.
  User? get currentUser {
    if (!configured) return null;
    final user = _auth.currentUser;
    return user == null || user.isAnonymous ? null : user;
  }

  Stream<AuthState> get changes => configured
      ? _auth.onAuthStateChange.where(
          (s) =>
              s.event == AuthChangeEvent.signedOut ||
              !(s.session?.user.isAnonymous ?? false),
        )
      : const Stream.empty();

  /// Sign in with Apple is offered on Apple platforms only. On Android it
  /// would need the web flow and a Services ID secret that expires every six
  /// months; App Store guideline 4.8 applies to the iOS app.
  Future<bool> appleAvailable() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return false;
    try {
      return await SignInWithApple.isAvailable();
    } on Object {
      return false;
    }
  }

  bool get googleAvailable => AuthConfig.googleConfigured;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) => _guard(() async {
    await _auth.signInWithPassword(
      email: normalizeEmail(email),
      password: password,
    );
  });

  Future<SignUpOutcome> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) => _guard(() async {
    final name = displayName?.trim();
    final res = await _auth.signUp(
      email: normalizeEmail(email),
      password: password,
      emailRedirectTo: AuthConfig.redirectUrl,
      data: name == null || name.isEmpty ? null : {'full_name': name},
    );
    // With "Confirm email" on, an address that already has an account
    // comes back as a user with no identities instead of an error.
    final identities = res.user?.identities;
    if (res.session == null && identities != null && identities.isEmpty) {
      throw const AuthFlowException(AuthFailure.emailTaken);
    }
    return res.session != null
        ? SignUpOutcome.signedIn
        : SignUpOutcome.confirmEmail;
  });

  /// Emails a reset link. It opens the app through [AuthConfig.redirectUrl];
  /// supabase_flutter reads it and reports `passwordRecovery`, and the app
  /// then asks for the new password ([setNewPassword]).
  Future<void> sendPasswordResetLink(String email) => _guard(
    () => _auth.resetPasswordForEmail(
      normalizeEmail(email),
      redirectTo: AuthConfig.redirectUrl,
    ),
  );

  /// Sets the password of the signed-in traveler (after a reset link).
  Future<void> setNewPassword(String password) => _guard(() async {
    await _auth.updateUser(UserAttributes(password: password));
  });

  bool _googleReady = false;

  Future<void> signInWithGoogle() => _guard(() async {
    if (!AuthConfig.googleConfigured) {
      throw const AuthFlowException(AuthFailure.notConfigured, 'google');
    }
    final google = GoogleSignIn.instance;
    if (!_googleReady) {
      await google.initialize(
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? AuthConfig.googleIosClientId
            : null,
        serverClientId: AuthConfig.googleWebClientId,
      );
      _googleReady = true;
    }
    final GoogleSignInAccount account;
    try {
      account = await google.authenticate();
    } on GoogleSignInException catch (e) {
      throw AuthFlowException(
        e.code == GoogleSignInExceptionCode.canceled
            ? AuthFailure.cancelled
            : AuthFailure.unknown,
        'google ${e.code.name}',
      );
    }
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AuthFlowException(AuthFailure.unknown, 'google: no id token');
    }
    // The access token lets Supabase check the ID token's at_hash claim.
    // Usually granted silently; a second consent sheet the traveler closes
    // counts as cancelling.
    const scopes = ['email', 'profile'];
    final GoogleSignInClientAuthorization authorization;
    try {
      authorization =
          await account.authorizationClient.authorizationForScopes(scopes) ??
          await account.authorizationClient.authorizeScopes(scopes);
    } on GoogleSignInException catch (e) {
      throw AuthFlowException(
        e.code == GoogleSignInExceptionCode.canceled
            ? AuthFailure.cancelled
            : AuthFailure.unknown,
        'google scopes ${e.code.name}',
      );
    }
    await _auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: authorization.accessToken,
    );
  });

  Future<void> signInWithApple() => _guard(() async {
    final rawNonce = generateRawNonce();
    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256Hex(rawNonce),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      throw AuthFlowException(
        e.code == AuthorizationErrorCode.canceled
            ? AuthFailure.cancelled
            : AuthFailure.unknown,
        'apple ${e.code.name}',
      );
    }
    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const AuthFlowException(AuthFailure.unknown, 'apple: no id token');
    }
    await _auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
    // Apple sends the name only on the very first sign-in; keep it.
    final name = [
      credential.givenName,
      credential.familyName,
    ].whereType<String>().where((p) => p.trim().isNotEmpty).join(' ');
    if (name.isNotEmpty) {
      await _auth.updateUser(UserAttributes(data: {'full_name': name}));
      // The profile row was made by the sign-up trigger before the name was
      // known; fill it only where the traveler has not set one.
      final id = _auth.currentUser?.id;
      if (id != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({'display_name': name})
            .eq('id', id)
            .isFilter('display_name', null);
      }
    }
  });

  Future<void> signOut() => _guard(() async {
    if (_googleReady) {
      try {
        await GoogleSignIn.instance.signOut();
      } on Object {
        // Signing out of Supabase below is what matters.
      }
    }
    await _auth.signOut();
  });

  /// Deletes the account and everything saved with it
  /// (`public.delete_my_account`), then clears the local session.
  Future<void> deleteAccount() => _guard(() async {
    await Supabase.instance.client.rpc<void>('delete_my_account');
    try {
      await _auth.signOut();
    } on AuthException {
      // The user no longer exists; the local session is cleared anyway.
    }
  });

  Future<T> _guard<T>(Future<T> Function() run) async {
    if (!configured) {
      throw const AuthFlowException(AuthFailure.notConfigured, 'supabase');
    }
    try {
      return await run();
    } on AuthFlowException {
      rethrow;
    } on AuthException catch (e) {
      throw AuthFlowException(
        classifyAuthError(
          code: e.code,
          statusCode: int.tryParse(e.statusCode ?? ''),
          message: e.message,
        ),
        '${e.code} ${e.statusCode}',
      );
    } on PostgrestException catch (e) {
      throw AuthFlowException(
        classifyAuthError(code: e.code, message: e.message),
        'postgrest ${e.code}',
      );
    } on Object catch (e) {
      throw AuthFlowException(
        classifyAuthError(message: e.toString()),
        e.runtimeType.toString(),
      );
    }
  }
}
