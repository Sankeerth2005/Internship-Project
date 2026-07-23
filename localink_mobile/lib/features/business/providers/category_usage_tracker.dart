import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CategoryUsageNotifier extends AsyncNotifier<Map<int, int>> {
  static const _storage = FlutterSecureStorage();
  static const _storageKey = 'category_usage_weights';

  @override
  Future<Map<int, int>> build() async {
    try {
      final jsonStr = await _storage.read(key: _storageKey);
      if (jsonStr != null) {
        final Map<String, dynamic> rawMap = json.decode(jsonStr);
        return rawMap.map((key, value) => MapEntry(int.parse(key), value as int));
      }
    } catch (_) {}
    return {};
  }

  Future<void> increment(int categoryId, int weight) async {
    final currentMap = state.value ?? {};
    final newCount = (currentMap[categoryId] ?? 0) + weight;
    final newMap = {...currentMap, categoryId: newCount};
    state = AsyncData(newMap);

    try {
      final stringMap = newMap.map((key, value) => MapEntry(key.toString(), value));
      await _storage.write(key: _storageKey, value: json.encode(stringMap));
    } catch (_) {}
  }
}

final categoryUsageProvider = AsyncNotifierProvider<CategoryUsageNotifier, Map<int, int>>(
  CategoryUsageNotifier.new,
);
