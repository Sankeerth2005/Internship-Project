import 'package:shared_preferences/shared_preferences.dart';

/// Persists the last home search query for offline restore.
class LastSearchStore {
  static const _key = 'last_home_search_v1';

  static Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }

  static Future<void> save(String query) async {
    final q = query.trim();
    final prefs = await SharedPreferences.getInstance();
    if (q.length < 2) {
      await prefs.remove(_key);
      return;
    }
    await prefs.setString(_key, q);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
