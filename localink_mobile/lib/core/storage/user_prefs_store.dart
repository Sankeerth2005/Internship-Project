import 'package:shared_preferences/shared_preferences.dart';

/// Persisted user display preferences (currency, etc.).
///
/// Currency is scoped per userId so preferences never leak across accounts
/// on the same device.
class UserPrefsStore {
  static const _legacyCurrencyKey = 'user_currency_v1';
  static const _userAgreementKeyPrefix = 'user_agreement_accepted_v1_';
  static const _pendingAgreementEmailKey = 'pending_user_agreement_email_v1';
  static const defaultCurrency = 'INR';

  /// Offline fallback when exchange-rate API is unavailable.
  static const fallbackCurrencies = <String>[
    'INR',
    'USD',
    'EUR',
    'GBP',
    'AED',
    'SGD',
    'CAD',
    'AUD',
    'JPY',
    'CNY',
  ];

  static String _currencyKeyFor(int userId) => '${_legacyCurrencyKey}_$userId';

  /// Returns the preferred currency for [userId].
  ///
  /// If no per-user value exists, migrates once from the legacy global key
  /// (when present), then falls back to [defaultCurrency].
  /// When [userId] is null (logged out), returns [defaultCurrency] without writing.
  static Future<String> getCurrency({required int? userId}) async {
    if (userId == null) return defaultCurrency;

    final prefs = await SharedPreferences.getInstance();
    final key = _currencyKeyFor(userId);
    final scoped = prefs.getString(key);
    if (scoped != null && scoped.isNotEmpty) return scoped;

    // One-time migration from pre-scoped global key.
    final legacy = prefs.getString(_legacyCurrencyKey);
    if (legacy != null && legacy.isNotEmpty) {
      await prefs.setString(key, legacy.toUpperCase());
      await prefs.remove(_legacyCurrencyKey);
      return legacy.toUpperCase();
    }

    return defaultCurrency;
  }

  /// Persists currency for [userId]. No-op when [userId] is null.
  static Future<void> setCurrency({
    required int? userId,
    required String code,
  }) async {
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKeyFor(userId), code.toUpperCase());
  }

  /// Removes the legacy device-global currency key so it cannot apply to
  /// another account after logout. Per-user keys are left intact.
  static Future<void> clearLegacyCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyCurrencyKey);
  }

  static String _agreementKeyFor(int userId) =>
      '$_userAgreementKeyPrefix$userId';

  /// True when this account already accepted the one-time User Agreement.
  static Future<bool> hasAcceptedUserAgreement(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_agreementKeyFor(userId)) ?? false;
  }

  /// Persists one-time User Agreement acceptance for [userId].
  static Future<void> setAcceptedUserAgreement(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_agreementKeyFor(userId), true);
  }

  /// Marks an email/password signup that must accept the agreement after login.
  static Future<void> markPendingAgreementEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _pendingAgreementEmailKey,
      email.trim().toLowerCase(),
    );
  }

  static Future<String?> getPendingAgreementEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_pendingAgreementEmailKey);
    if (value == null || value.isEmpty) return null;
    return value;
  }

  static Future<void> clearPendingAgreementEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingAgreementEmailKey);
  }
}
