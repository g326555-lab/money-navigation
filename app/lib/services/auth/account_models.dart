/// The signed-in traveler's profile, as stored in `public.profiles`
/// (supabase/migrations/20261015090000_accounts.sql). Pure Dart.
library;

final _currencyCode = RegExp(r'^[A-Z]{3}$');

/// Longest display name, as `profiles.display_name` allows.
const int maxDisplayNameLength = 80;

/// Which half of the app the traveler uses.
enum TravelerType {
  /// Part A: a visitor paying in baht, English UI.
  visitorInThailand('visitor_in_thailand'),

  /// Part B: a Thai traveler paying abroad, Thai UI.
  thaiAbroad('thai_abroad');

  const TravelerType(this.dbValue);

  final String dbValue;

  static TravelerType? fromDb(Object? value) {
    for (final t in values) {
      if (t.dbValue == value) return t;
    }
    return null;
  }
}

enum AppLanguage {
  en('en'),
  th('th');

  const AppLanguage(this.dbValue);

  final String dbValue;

  static AppLanguage? fromDb(Object? value) {
    for (final l in values) {
      if (l.dbValue == value) return l;
    }
    return null;
  }
}

bool isCurrencyCode(Object? value) =>
    value is String && _currencyCode.hasMatch(value);

class Profile {
  const Profile({
    required this.id,
    this.displayName,
    this.travelerType,
    this.homeCurrency,
    this.cardCurrency,
    this.language,
    this.onboardedAt,
  });

  final String id;
  final String? displayName;
  final TravelerType? travelerType;
  final String? homeCurrency;
  final String? cardCurrency;
  final AppLanguage? language;

  /// When the first-run questions were answered; null until then.
  final DateTime? onboardedAt;

  /// True once the first-run questions are answered and the app can open.
  bool get isComplete =>
      onboardedAt != null &&
      travelerType != null &&
      homeCurrency != null &&
      cardCurrency != null &&
      language != null;

  /// Null when [row] is not a profile row. Values the app does not know
  /// become null instead of failing, so an old row never locks anyone out.
  static Profile? fromRow(Object? row) {
    if (row is! Map) return null;
    final id = row['id'];
    if (id is! String || id.isEmpty) return null;
    final name = row['display_name'];
    final onboarded = row['onboarded_at'];
    return Profile(
      id: id,
      displayName: name is String && name.trim().isNotEmpty ? name : null,
      travelerType: TravelerType.fromDb(row['traveler_type']),
      homeCurrency: _code(row['home_currency']),
      cardCurrency: _code(row['card_currency']),
      language: AppLanguage.fromDb(row['language']),
      onboardedAt: onboarded is String ? DateTime.tryParse(onboarded) : null,
    );
  }

  /// The columns the first-run screen writes.
  Map<String, Object?> toSetupRow() => {
    if (displayName != null) 'display_name': displayName,
    'traveler_type': travelerType?.dbValue,
    'home_currency': homeCurrency,
    'card_currency': cardCurrency,
    'language': language?.dbValue,
    'onboarded_at': onboardedAt?.toUtc().toIso8601String(),
  };

  Profile copyWith({
    String? displayName,
    TravelerType? travelerType,
    String? homeCurrency,
    String? cardCurrency,
    AppLanguage? language,
    DateTime? onboardedAt,
  }) => Profile(
    id: id,
    displayName: displayName ?? this.displayName,
    travelerType: travelerType ?? this.travelerType,
    homeCurrency: homeCurrency ?? this.homeCurrency,
    cardCurrency: cardCurrency ?? this.cardCurrency,
    language: language ?? this.language,
    onboardedAt: onboardedAt ?? this.onboardedAt,
  );
}

String? _code(Object? value) => isCurrencyCode(value) ? value as String : null;

/// The answers on the first-run screen before they are saved.
class ProfileDraft {
  const ProfileDraft({
    required this.travelerType,
    required this.homeCurrency,
    required this.cardCurrency,
    required this.language,
  });

  final TravelerType travelerType;
  final String homeCurrency;
  final String cardCurrency;
  final AppLanguage language;

  bool get isValid =>
      isCurrencyCode(homeCurrency) && isCurrencyCode(cardCurrency);

  ProfileDraft copyWith({
    TravelerType? travelerType,
    String? homeCurrency,
    String? cardCurrency,
    AppLanguage? language,
  }) => ProfileDraft(
    travelerType: travelerType ?? this.travelerType,
    homeCurrency: homeCurrency ?? this.homeCurrency,
    cardCurrency: cardCurrency ?? this.cardCurrency,
    language: language ?? this.language,
  );

  Profile toProfile(String id, {String? displayName, required DateTime now}) =>
      Profile(
        id: id,
        displayName: displayName,
        travelerType: travelerType,
        homeCurrency: homeCurrency,
        cardCurrency: cardCurrency,
        language: language,
        onboardedAt: now,
      );
}

/// What the first-run screen starts with for each kind of traveler.
///
/// A visitor in Thailand thinks in their own currency, so it comes from the
/// phone's region; baht is never their home currency, so a Thai-region phone
/// falls back to US dollars. A Thai traveler thinks and is billed in baht.
ProfileDraft defaultsFor(TravelerType type, {required String deviceCurrency}) {
  switch (type) {
    case TravelerType.visitorInThailand:
      final home = isCurrencyCode(deviceCurrency) && deviceCurrency != 'THB'
          ? deviceCurrency
          : 'USD';
      return ProfileDraft(
        travelerType: type,
        homeCurrency: home,
        cardCurrency: home,
        language: AppLanguage.en,
      );
    case TravelerType.thaiAbroad:
      return const ProfileDraft(
        travelerType: TravelerType.thaiAbroad,
        homeCurrency: 'THB',
        cardCurrency: 'THB',
        language: AppLanguage.th,
      );
  }
}
