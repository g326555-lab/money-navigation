/// Why a sign-in step did not succeed, in terms the screens can explain.
/// Pure Dart: the Supabase and platform errors are classified by their codes
/// in [classifyAuthError].
library;

enum AuthFailure {
  /// The traveler closed the Apple or Google sheet. Not an error to show.
  cancelled,
  invalidCredentials,
  emailTaken,
  emailNotConfirmed,
  weakPassword,

  /// The emailed link is wrong or has expired.
  codeInvalid,

  /// Supabase will not accept this address.
  emailRejected,

  /// The project cannot send mail to this address (the built-in mail
  /// service only reaches the team's own addresses).
  emailUndeliverable,
  rateLimited,
  offline,

  /// This build has no client ID for the provider (or no Supabase env).
  notConfigured,
  unknown,
}

class AuthFlowException implements Exception {
  const AuthFlowException(this.failure, [this.detail]);

  final AuthFailure failure;

  /// For logs only; never shown to the traveler.
  final String? detail;

  @override
  String toString() =>
      'AuthFlowException(${failure.name}${detail == null ? '' : ': $detail'})';
}

/// Maps a Supabase Auth error (its `code` from
/// https://supabase.com/docs/guides/auth/debugging/error-codes) or a network
/// error message to an [AuthFailure]. The code wins over the message.
AuthFailure classifyAuthError({
  String? code,
  int? statusCode,
  String? message,
}) {
  switch (code) {
    case 'invalid_credentials':
      return AuthFailure.invalidCredentials;
    case 'user_already_exists' || 'email_exists':
      return AuthFailure.emailTaken;
    case 'email_not_confirmed':
      return AuthFailure.emailNotConfirmed;
    case 'otp_expired' || 'flow_state_expired' || 'flow_state_not_found':
      return AuthFailure.codeInvalid;
    case 'email_address_invalid':
      return AuthFailure.emailRejected;
    case 'email_address_not_authorized':
      return AuthFailure.emailUndeliverable;
    case 'weak_password' || 'same_password':
      return AuthFailure.weakPassword;
    case 'over_request_rate_limit' || 'over_email_send_rate_limit':
      return AuthFailure.rateLimited;
  }
  if (statusCode == 429) return AuthFailure.rateLimited;
  final text = message ?? '';
  if (text.contains('SocketException') ||
      text.contains('TimeoutException') ||
      text.contains('Failed host lookup') ||
      text.contains('Connection refused')) {
    return AuthFailure.offline;
  }
  return AuthFailure.unknown;
}
