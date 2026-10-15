import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../rules/personal_context.dart';

/// The traveler's card facts for the pay-way comparison: the card's foreign
/// transaction fee and what their home bank charges at a foreign ATM.
///
/// Typed in on the Assistant tab and kept on the phone. When the account
/// profile has a value and nothing was typed here, the account's is used.
class CardProfileStore extends ChangeNotifier {
  CardProfileStore({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const _feeKey = 'assist.cardFeePercent';
  static const _policyKey = 'assist.atmFeePolicy';
  static const _valueKey = 'assist.atmFeeValue';

  /// The highest card fee the profile table accepts.
  static const maxFeePercent = 20.0;

  final SharedPreferencesAsync _prefs;
  TravelerProfile _local = const TravelerProfile();
  TravelerProfile _account = const TravelerProfile();
  bool _loaded = false;

  bool get loaded => _loaded;

  /// Typed-in facts first, the account's where nothing was typed.
  TravelerProfile get profile => TravelerProfile(
    cardFeePercent: _local.cardFeePercent ?? _account.cardFeePercent,
    atmFeePolicy: _local.atmFeePolicy != AtmFeePolicy.unknown
        ? _local.atmFeePolicy
        : _account.atmFeePolicy,
    atmFeeValue: _local.atmFeePolicy != AtmFeePolicy.unknown
        ? _local.atmFeeValue
        : _account.atmFeeValue,
  );

  /// The card fee came from the signed-in account, not this phone.
  bool get feeFromAccount =>
      _local.cardFeePercent == null && _account.cardFeePercent != null;

  Future<void> load() async {
    try {
      final fee = await _prefs.getDouble(_feeKey);
      final policy = AtmFeePolicy.values
          .asNameMap()[await _prefs.getString(_policyKey)];
      final value = await _prefs.getDouble(_valueKey);
      _local = TravelerProfile(
        cardFeePercent: fee,
        atmFeePolicy: policy ?? AtmFeePolicy.unknown,
        atmFeeValue: value,
      );
    } on Object {
      _local = const TravelerProfile();
    }
    _loaded = true;
    notifyListeners();
  }

  /// The signed-in account's card facts (from PersonalMemory).
  void useAccount(TravelerProfile account) {
    _account = account;
    notifyListeners();
  }

  Future<void> setCardFee(double? percent) async {
    if (percent != null && (percent < 0 || percent > maxFeePercent)) {
      throw ArgumentError.value(percent, 'percent');
    }
    _local = TravelerProfile(
      cardFeePercent: percent,
      atmFeePolicy: _local.atmFeePolicy,
      atmFeeValue: _local.atmFeeValue,
    );
    notifyListeners();
    try {
      if (percent == null) {
        await _prefs.remove(_feeKey);
      } else {
        await _prefs.setDouble(_feeKey, percent);
      }
    } on Object {
      // Kept for this session; the next launch asks again.
    }
  }

  Future<void> setAtmPolicy(AtmFeePolicy policy, {double? value}) async {
    _local = TravelerProfile(
      cardFeePercent: _local.cardFeePercent,
      atmFeePolicy: policy,
      atmFeeValue: value,
    );
    notifyListeners();
    try {
      await _prefs.setString(_policyKey, policy.name);
      if (value == null) {
        await _prefs.remove(_valueKey);
      } else {
        await _prefs.setDouble(_valueKey, value);
      }
    } on Object {
      // Kept for this session.
    }
  }
}
