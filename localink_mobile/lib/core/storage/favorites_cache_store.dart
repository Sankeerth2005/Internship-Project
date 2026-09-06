import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/business/data/models/business_models.dart';

/// Disk cache for favorite business cards — used when offline / load fails.
class FavoritesCacheStore {
  static String _keyFor(int userId) => 'favorites_businesses_cache_v1_$userId';

  static Future<List<BusinessDto>> load(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(userId));
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List? ?? [];
      return list
          .map((e) => BusinessDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> save(int userId, List<BusinessDto> businesses) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(businesses.map((b) => b.toJson()).toList());
    await prefs.setString(_keyFor(userId), encoded);
  }

  static Future<void> clear(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor(userId));
  }
}
