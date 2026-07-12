import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../data/models/business_models.dart';
import '../data/repositories/business_repository.dart';

final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  return BusinessRepository(dio: DioClient().dio);
});

// Categories list provider
final categoriesProvider = FutureProvider<List<CategoryDto>>((ref) async {
  final repo = ref.watch(businessRepositoryProvider);
  return await repo.getCategories();
});

// Subcategories by category provider
final subcategoriesProvider = FutureProvider.family<List<SubcategoryDto>, int>((ref, categoryId) async {
  final repo = ref.watch(businessRepositoryProvider);
  return await repo.getSubcategories(categoryId);
});

// User owned businesses provider for Dashboard
class MyBusinessesNotifier extends AsyncNotifier<List<BusinessDto>> {
  @override
  Future<List<BusinessDto>> build() async {
    return _fetch();
  }

  Future<List<BusinessDto>> _fetch() async {
    final repo = ref.read(businessRepositoryProvider);
    return await repo.getMyBusinesses();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<int> register(BusinessDto business) async {
    final repo = ref.read(businessRepositoryProvider);
    final id = await repo.registerBusiness(business);
    await refresh();
    return id;
  }

  Future<bool> updateBusinessProfile(int id, BusinessDto business) async {
    final repo = ref.read(businessRepositoryProvider);
    final success = await repo.updateBusiness(id, business);
    await refresh();
    return success;
  }
}

final myBusinessesProvider = AsyncNotifierProvider<MyBusinessesNotifier, List<BusinessDto>>(
  MyBusinessesNotifier.new,
);

// Search and filter query state notifier
class SearchQueryState {
  final String query;
  final int? selectedCategoryId;
  final double? latitude;
  final double? longitude;
  final bool isVoiceSearch;

  SearchQueryState({
    this.query = '',
    this.selectedCategoryId,
    this.latitude,
    this.longitude,
    this.isVoiceSearch = false,
  });

  SearchQueryState copyWith({
    String? query,
    int? selectedCategoryId,
    double? latitude,
    double? longitude,
    bool? isVoiceSearch,
    bool clearCategory = false,
  }) {
    return SearchQueryState(
      query: query ?? this.query,
      selectedCategoryId: clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isVoiceSearch: isVoiceSearch ?? this.isVoiceSearch,
    );
  }
}

class SearchQueryNotifier extends Notifier<SearchQueryState> {
  @override
  SearchQueryState build() {
    return SearchQueryState();
  }

  void setQuery(String q, {bool isVoice = false}) {
    state = state.copyWith(query: q, isVoiceSearch: isVoice);
  }
  void setCategory(int? id) => state = state.copyWith(selectedCategoryId: id, isVoiceSearch: false);
  void clearCategory() => state = state.copyWith(clearCategory: true, isVoiceSearch: false);
  void setLocation(double lat, double lng) => state = state.copyWith(latitude: lat, longitude: lng);
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, SearchQueryState>(
  SearchQueryNotifier.new,
);

// Search results provider based on query state
final searchResultsProvider = FutureProvider<List<BusinessDto>>((ref) async {
  final queryState = ref.watch(searchQueryProvider);
  final repo = ref.watch(businessRepositoryProvider);

  if (queryState.query.isEmpty && queryState.selectedCategoryId == null) {
    return await repo.getAllBusinesses();
  }

  if (queryState.isVoiceSearch && queryState.query.isNotEmpty) {
    // Call voice search text API which runs structured search on backend
    return await repo.voiceSearchText(
      queryState.query,
      lat: queryState.latitude,
      lng: queryState.longitude,
    );
  }

  // If query is empty but category is selected, load all businesses and filter locally
  if (queryState.query.isEmpty && queryState.selectedCategoryId != null) {
    final all = await repo.getAllBusinesses();
    return all.where((b) => b.categoryId == queryState.selectedCategoryId).toList();
  }

  // Filter or search normally
  final results = await repo.searchBusinesses(
    queryState.query,
    latitude: queryState.latitude,
    longitude: queryState.longitude,
  );

  if (queryState.selectedCategoryId != null) {
    return results.where((b) => b.categoryId == queryState.selectedCategoryId).toList();
  }

  return results;
});

// Reviews provider for business details
final reviewsProvider = FutureProvider.family<List<BusinessReviewDto>, int>((ref, businessId) async {
  final repo = ref.watch(businessRepositoryProvider);
  return await repo.getReviews(businessId);
});

// Favorites Provider (Local simulation mapping)
class FavoritesNotifier extends Notifier<List<int>> {
  @override
  List<int> build() {
    return [];
  }

  void toggleFavorite(int businessId) {
    if (state.contains(businessId)) {
      state = state.where((id) => id != businessId).toList();
    } else {
      state = [...state, businessId];
    }
  }

  bool isFavorite(int businessId) => state.contains(businessId);
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, List<int>>(
  FavoritesNotifier.new,
);

final singleBusinessProvider = FutureProvider.family<BusinessDto, int>((ref, id) async {
  final repo = ref.watch(businessRepositoryProvider);
  return await repo.getBusinessById(id);
});
