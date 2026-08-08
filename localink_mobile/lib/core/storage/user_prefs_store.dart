import 'package:shared_preferences/shared_preferences.dart';

/// Persisted user display preferences (currency, etc.).
class UserPrefsStore {
  static const _currencyKey = 'user_currency_v1';
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

  static Future<String> getCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_currencyKey);
    if (value == null || value.isEmpty) return defaultCurrency;
    return value;
  }

  static Future<void> setCurrency(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, code.toUpperCase());
  }
}
