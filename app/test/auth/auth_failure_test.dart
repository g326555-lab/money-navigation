import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/services/auth/auth_failure.dart';

void main() {
  group('classifyAuthError: GoTrue codes', () {
    test('invalid_credentials', () {
      expect(
        classifyAuthError(code: 'invalid_credentials', statusCode: 400),
        AuthFailure.invalidCredentials,
      );
    });

    test('user_already_exists and email_exists mean email taken', () {
      expect(
        classifyAuthError(code: 'user_already_exists'),
        AuthFailure.emailTaken,
      );
      expect(classifyAuthError(code: 'email_exists'), AuthFailure.emailTaken);
    });

    test('email_not_confirmed', () {
      expect(
        classifyAuthError(code: 'email_not_confirmed'),
        AuthFailure.emailNotConfirmed,
      );
    });

    test('weak_password', () {
      expect(
        classifyAuthError(code: 'weak_password', statusCode: 422),
        AuthFailure.weakPassword,
      );
    });

    test('same_password is a weak password', () {
      expect(
        classifyAuthError(code: 'same_password'),
        AuthFailure.weakPassword,
      );
    });

    test('otp_expired means the reset code is invalid', () {
      expect(
        classifyAuthError(code: 'otp_expired', statusCode: 403),
        AuthFailure.codeInvalid,
      );
    });

    test('expired or missing flow state means the link is invalid', () {
      expect(
        classifyAuthError(code: 'flow_state_expired'),
        AuthFailure.codeInvalid,
      );
      expect(
        classifyAuthError(code: 'flow_state_not_found'),
        AuthFailure.codeInvalid,
      );
    });

    test('email_address_invalid is rejected', () {
      expect(
        classifyAuthError(code: 'email_address_invalid', statusCode: 400),
        AuthFailure.emailRejected,
      );
    });

    test('email_address_not_authorized is undeliverable', () {
      expect(
        classifyAuthError(code: 'email_address_not_authorized'),
        AuthFailure.emailUndeliverable,
      );
    });

    test('both rate limit codes', () {
      expect(
        classifyAuthError(code: 'over_request_rate_limit'),
        AuthFailure.rateLimited,
      );
      expect(
        classifyAuthError(code: 'over_email_send_rate_limit'),
        AuthFailure.rateLimited,
      );
    });
  });

  group('classifyAuthError: status and message fallbacks', () {
    test('HTTP 429 without a code is rate limited', () {
      expect(classifyAuthError(statusCode: 429), AuthFailure.rateLimited);
    });

    test('network failures are offline', () {
      expect(
        classifyAuthError(
          message: 'ClientException with SocketException: Network is down',
        ),
        AuthFailure.offline,
      );
      expect(
        classifyAuthError(message: "Failed host lookup: 'x.supabase.co'"),
        AuthFailure.offline,
      );
      expect(
        classifyAuthError(message: 'Connection refused (OS Error)'),
        AuthFailure.offline,
      );
      expect(
        classifyAuthError(
          message:
              'TimeoutException after 0:00:10.000000: Future not completed',
        ),
        AuthFailure.offline,
      );
    });

    test('code takes precedence over an offline-looking message', () {
      expect(
        classifyAuthError(
          code: 'invalid_credentials',
          message: 'SocketException',
        ),
        AuthFailure.invalidCredentials,
      );
    });

    test('unrecognized input is unknown', () {
      expect(classifyAuthError(), AuthFailure.unknown);
      expect(
        classifyAuthError(code: 'something_new', statusCode: 500),
        AuthFailure.unknown,
      );
      expect(
        classifyAuthError(statusCode: 400, message: 'Bad request'),
        AuthFailure.unknown,
      );
    });

    test('enum lists every failure the UI can show', () {
      expect(AuthFailure.values.map((f) => f.name), [
        'cancelled',
        'invalidCredentials',
        'emailTaken',
        'emailNotConfirmed',
        'weakPassword',
        'codeInvalid',
        'emailRejected',
        'emailUndeliverable',
        'rateLimited',
        'offline',
        'notConfigured',
        'unknown',
      ]);
    });
  });

  group('AuthFlowException', () {
    test('carries the failure and an optional detail', () {
      const e = AuthFlowException(AuthFailure.offline);
      expect(e.failure, AuthFailure.offline);
      expect(e.detail, isNull);
      const d = AuthFlowException(AuthFailure.notConfigured, 'google');
      expect(d.failure, AuthFailure.notConfigured);
      expect(d.detail, 'google');
      expect(d, isA<Exception>());
    });
  });
}
