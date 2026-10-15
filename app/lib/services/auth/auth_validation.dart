/// Checks for what the traveler types on the email screens. Pure Dart so
/// the rules are tested without a device.
library;

/// Shortest password the app accepts. The Supabase project enforces the
/// same minimum (Authentication > Providers > Email).
const int minPasswordLength = 8;

enum EmailProblem { empty, malformed }

enum PasswordProblem { empty, tooShort }

final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[A-Za-z]{2,}$');

/// Null when [input] reads as an email address.
EmailProblem? checkEmail(String input) {
  final value = input.trim();
  if (value.isEmpty) return EmailProblem.empty;
  if (!_email.hasMatch(value)) return EmailProblem.malformed;
  final domain = value.substring(value.indexOf('@') + 1);
  if (domain.startsWith('.') || domain.contains('..')) {
    return EmailProblem.malformed;
  }
  return null;
}

/// The form an address is sent and stored in.
String normalizeEmail(String input) => input.trim().toLowerCase();

/// Null when [input] is long enough. Spaces count: a password is never
/// trimmed.
PasswordProblem? checkPassword(String input) {
  if (input.isEmpty) return PasswordProblem.empty;
  if (input.length < minPasswordLength) return PasswordProblem.tooShort;
  return null;
}
