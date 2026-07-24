import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/models/catalog_models.dart';
import '../../data/repositories/catalog_repository.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  final dioClient = DioClient();
  return CatalogRepository(dioClient);
});

final catalogsProvider = FutureProvider.family<List<Catalog>, int>((ref, businessId) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getCatalogs(businessId);
});

class CatalogNotifier extends Notifier<AsyncValue<void>> {
  late final CatalogRepository _repository;

  @override
  AsyncValue<void> build() {
    _repository = ref.watch(catalogRepositoryProvider);
    return const AsyncValue.data(null);
  }

  Future<void> createCatalog(int businessId, String title, String? description) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createCatalog(businessId, title, description);
      ref.invalidate(catalogsProvider(businessId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateCatalog(int businessId, int catalogId, String title, String? description) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateCatalog(catalogId, title, description);
      ref.invalidate(catalogsProvider(businessId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteCatalog(int businessId, int catalogId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteCatalog(catalogId);
      ref.invalidate(catalogsProvider(businessId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCatalogItem(
    int businessId,
    int catalogId,
    String name,
    String? description,
    double price,
    bool isAvailable,
    File? image,
  ) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addCatalogItem(catalogId, name, description, price, isAvailable, image);
      ref.invalidate(catalogsProvider(businessId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateCatalogItem(
    int businessId,
    int itemId,
    String name,
    String? description,
    double price,
    bool isAvailable,
    File? image,
  ) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateCatalogItem(itemId, name, description, price, isAvailable, image);
      ref.invalidate(catalogsProvider(businessId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteCatalogItem(int businessId, int itemId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteCatalogItem(itemId);
      ref.invalidate(catalogsProvider(businessId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final catalogNotifierProvider = NotifierProvider<CatalogNotifier, AsyncValue<void>>(() {
  return CatalogNotifier();
});
