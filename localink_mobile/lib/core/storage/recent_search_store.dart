import 'package:shared_preferences/shared_preferences.dart';

/// Persists only real user search terms — never seeded with mock categories.
class RecentSearchStore {
  static const _key = 'recent_searches_v1';
  static const _max = 8;

  static Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? const [];
  }

  static Future<List<String>> add(String raw) async {
    final q = raw.trim();
    if (q.length < 2) return load();

    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? <String>[];
    current.removeWhere((e) => e.toLowerCase() == q.toLowerCase());
    current.insert(0, q);
    if (current.length > _max) {
      current.removeRange(_max, current.length);
    }
    await prefs.setStringList(_key, current);
    return current;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
