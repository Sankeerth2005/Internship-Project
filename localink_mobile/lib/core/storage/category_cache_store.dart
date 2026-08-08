import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/business/data/models/business_models.dart';

/// Disk cache for category list — used when offline / cold start before network.
class CategoryCacheStore {
  static const _key = 'categories_cache_v1';

  static Future<List<CategoryDto>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List? ?? [];
      return list
          .map((e) => CategoryDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> save(List<CategoryDto> categories) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(categories.map((c) => c.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
