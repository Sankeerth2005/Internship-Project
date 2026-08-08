import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../data/models/business_models.dart';
import '../data/repositories/business_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/auth_state.dart';
import '../../auth/providers/user_provider.dart';
import 'category_usage_tracker.dart';

final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  return BusinessRepository(dio: DioClient().dio);
});

// Categories list provider
final categoriesProvider = FutureProvider<List<CategoryDto>>((ref) async {
  final repo = ref.watch(businessRepositoryProvider);
  return await repo.getCategories();
});

// Sorted categories provider by usage
final sortedCategoriesProvider = FutureProvider<List<CategoryDto>>((ref) async {
  final categories = await ref.watch(categoriesProvider.future);
  final usageMap = ref.watch(categoryUsageProvider).value ?? {};

  final list = List<CategoryDto>.from(categories);
  list.sort((a, b) {
    final countA = usageMap[a.categoryId] ?? 0;
    final countB = usageMap[b.categoryId] ?? 0;
    return countB.compareTo(countA);
  });
  return list;
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
    ref.watch(authProvider); // Automatically rebuild on login/logout state changes
    return _fetch();
  }

  Future<List<BusinessDto>> _fetch() async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) {
      return [];
    }
    final repo = ref.read(businessRepositoryProvider);
    return await repo.getMyBusinesses();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
    ref.invalidate(searchFeedProvider);
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
    // Invalidate single business provider to refresh user's view
    ref.invalidate(singleBusinessProvider);
    return success;
  }

  Future<bool> requestTemporaryClosure(int id, String reason, int days) async {
    final repo = ref.read(businessRepositoryProvider);
    final success = await repo.requestTemporaryClosure(id, reason, days);
    await refresh();
    ref.invalidate(singleBusinessProvider);
    return success;
  }

  Future<bool> cancelTemporaryClosure(int id) async {
    final repo = ref.read(businessRepositoryProvider);
    final success = await repo.cancelTemporaryClosure(id);
    await refresh();
    ref.invalidate(singleBusinessProvider);
    return success;
  }

  Future<bool> requestDeletion(int id, String reason) async {
    final repo = ref.read(businessRepositoryProvider);
    final success = await repo.requestDeletion(id, reason);
    await refresh();
    ref.invalidate(singleBusinessProvider);
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
  final int? selectedSubcategoryId;
  final double? latitude;
  final double? longitude;
  final bool isVoiceSearch;
  final String sortBy;
  final String userPincode;
  final double radiusKm;
  final int page;
  final int pageSize;

  SearchQueryState({
    this.query = '',
    this.selectedCategoryId,
    this.selectedSubcategoryId,
    this.latitude,
    this.longitude,
    this.isVoiceSearch = false,
    this.sortBy = 'nearest',
    this.userPincode = '',
    this.radiusKm = 25,
    this.page = 1,
    this.pageSize = 20,
  });

  SearchQueryState copyWith({
    String? query,
    int? selectedCategoryId,
    int? selectedSubcategoryId,
    double? latitude,
    double? longitude,
    bool? isVoiceSearch,
    String? sortBy,
    String? userPincode,
    double? radiusKm,
    int? page,
    int? pageSize,
    bool clearCategory = false,
    bool clearSubcategory = false,
  }) {
    return SearchQueryState(
      query: query ?? this.query,
      selectedCategoryId: clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
      selectedSubcategoryId: (clearCategory || clearSubcategory) ? null : (selectedSubcategoryId ?? this.selectedSubcategoryId),
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isVoiceSearch: isVoiceSearch ?? this.isVoiceSearch,
      sortBy: sortBy ?? this.sortBy,
      userPincode: userPincode ?? this.userPincode,
      radiusKm: radiusKm ?? this.radiusKm,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

class SearchQueryNotifier extends Notifier<SearchQueryState> {
  @override
  SearchQueryState build() {
    return SearchQueryState();
  }

  void setQuery(String q, {bool isVoice = false}) {
    state = state.copyWith(query: q, isVoiceSearch: isVoice, page: 1);
  }
  void setCategory(int? id) => state = state.copyWith(selectedCategoryId: id, clearSubcategory: true, isVoiceSearch: false, page: 1);
  void setSubcategory(int? subId) => state = state.copyWith(selectedSubcategoryId: subId, isVoiceSearch: false, page: 1);
  void clearCategory() => state = state.copyWith(clearCategory: true, clearSubcategory: true, isVoiceSearch: false, page: 1);
  void clearSubcategory() => state = state.copyWith(clearSubcategory: true, isVoiceSearch: false, page: 1);
  void setLocation(double lat, double lng) => state = state.copyWith(latitude: lat, longitude: lng, page: 1);
  void setSortBy(String sort) => state = state.copyWith(sortBy: sort, page: 1);
  void setPincode(String pin) => state = state.copyWith(userPincode: pin, page: 1);
  void setRadius(double km) => state = state.copyWith(radiusKm: km, page: 1);
  void setPage(int page) => state = state.copyWith(page: page < 1 ? 1 : page);
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, SearchQueryState>(
  SearchQueryNotifier.new,
);

extension BusinessDtoExtension on BusinessDto {
  /// No fabricated owner names — show location context when useful.
  String get ownerName {
    if (city.isNotEmpty && state.isNotEmpty) return '$city, $state';
    if (city.isNotEmpty) return city;
    return '';
  }
}

class SearchFeedState {
  final List<BusinessDto> items;
  final bool hasNextPage;
  final bool isLoadingMore;
  final int page;
  final Object? error;

  const SearchFeedState({
    this.items = const [],
    this.hasNextPage = false,
    this.isLoadingMore = false,
    this.page = 1,
    this.error,
  });

  SearchFeedState copyWith({
    List<BusinessDto>? items,
    bool? hasNextPage,
    bool? isLoadingMore,
    int? page,
    Object? error,
    bool clearError = false,
  }) {
    return SearchFeedState(
      items: items ?? this.items,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      page: page ?? this.page,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SearchFeedNotifier extends AsyncNotifier<SearchFeedState> {
  @override
  Future<SearchFeedState> build() async {
    // Watch filter fields only (exclude page so loadMore does not reset)
    ref.watch(searchQueryProvider.select((s) => (
          s.query,
          s.selectedCategoryId,
          s.selectedSubcategoryId,
          s.latitude,
          s.longitude,
          s.sortBy,
          s.radiusKm,
          s.isVoiceSearch,
          s.userPincode,
          s.pageSize,
        )));
    return _fetchPage(page: 1, reset: true);
  }

  Future<SearchFeedState> _fetchPage({required int page, required bool reset}) async {
    final queryState = ref.read(searchQueryProvider);
    final repo = ref.read(businessRepositoryProvider);

    String resolvedPincode = queryState.userPincode;
    String resolvedCity = '';
    try {
      final profile = ref.read(userProfileProvider).value;
      if (profile != null) {
        if (resolvedPincode.isEmpty && profile.address.pincode != null) {
          resolvedPincode = profile.address.pincode!;
        }
        if (profile.address.city != null) {
          resolvedCity = profile.address.city!;
        }
      }
    } catch (_) {}

    if (queryState.isVoiceSearch && queryState.query.isNotEmpty) {
      final items = await repo.voiceSearchText(
        queryState.query,
        lat: queryState.latitude,
        lng: queryState.longitude,
      );
      return SearchFeedState(items: items, hasNextPage: false, page: 1);
    }

    final paged = await repo.searchBusinesses(
      queryState.query,
      latitude: queryState.latitude,
      longitude: queryState.longitude,
      sortBy: queryState.sortBy,
      userPincode: resolvedPincode,
      userCity: resolvedCity,
      categoryId: queryState.selectedCategoryId,
      subcategoryId: queryState.selectedSubcategoryId,
      radiusKm: queryState.radiusKm,
      page: page,
      pageSize: queryState.pageSize,
    );

    final previous = reset ? <BusinessDto>[] : (state.asData?.value.items ?? []);
    final merged = reset
        ? paged.items
        : [
            ...previous,
            ...paged.items.where(
              (b) => !previous.any((p) => p.businessId == b.businessId),
            ),
          ];

    return SearchFeedState(
      items: merged,
      hasNextPage: paged.hasNextPage,
      page: page,
    );
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || !current.hasNextPage || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true, clearError: true));
    final nextPage = current.page + 1;

    try {
      final next = await _fetchPage(page: nextPage, reset: false);
      state = AsyncData(next.copyWith(isLoadingMore: false));
    } catch (e) {
      state = AsyncData(current.copyWith(isLoadingMore: false, error: e));
    }
  }
}

final searchFeedProvider =
    AsyncNotifierProvider<SearchFeedNotifier, SearchFeedState>(SearchFeedNotifier.new);

// Backward-compatible list provider used by existing screens
final searchResultsProvider = Provider<AsyncValue<List<BusinessDto>>>((ref) {
  final feed = ref.watch(searchFeedProvider);
  return feed.when(
    data: (s) => AsyncData(s.items),
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
  );
});

// Reviews provider for business details
final reviewsProvider = FutureProvider.family<List<BusinessReviewDto>, int>((ref, businessId) async {
  final repo = ref.watch(businessRepositoryProvider);
  return await repo.getReviews(businessId);
});

// Favorites Provider (Linked to Backend API)
class FavoritesNotifier extends Notifier<List<int>> {
  @override
  List<int> build() {
    final authState = ref.watch(authProvider);
    if (authState is AuthAuthenticated) {
      final userId = authState.userId;
      Future.microtask(() => loadFavorites(userId));
    }
    return [];
  }

  Future<void> loadFavorites(int userId) async {
    try {
      final repo = ref.read(businessRepositoryProvider);
      final list = await repo.getFavorites(userId);
      state = list;
    } catch (_) {}
  }

  Future<void> toggleFavorite(int businessId) async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;
    final userId = authState.userId;

    final repo = ref.read(businessRepositoryProvider);
    final exists = state.contains(businessId);

    if (exists) {
      state = state.where((id) => id != businessId).toList();
      try {
        await repo.removeFavorite(userId, businessId);
        ref.invalidate(favoriteBusinessesProvider);
      } catch (_) {
        state = [...state, businessId]; // Rollback
      }
    } else {
      state = [...state, businessId];
      try {
        await repo.addFavorite(userId, businessId);
        ref.invalidate(favoriteBusinessesProvider);
      } catch (_) {
        state = state.where((id) => id != businessId).toList(); // Rollback
      }
    }
  }

  bool isFavorite(int businessId) => state.contains(businessId);
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, List<int>>(
  FavoritesNotifier.new,
);

/// Loads full business records for saved favorite IDs in one API call.
final favoriteBusinessesProvider = FutureProvider<List<BusinessDto>>((ref) async {
  final ids = ref.watch(favoritesProvider);
  if (ids.isEmpty) return [];

  final auth = ref.watch(authProvider);
  if (auth is! AuthAuthenticated) return [];

  final repo = ref.watch(businessRepositoryProvider);
  try {
    final list = await repo.getFavoriteBusinesses(auth.userId);
    // Preserve favorites-list order when possible
    final byId = {for (final b in list) b.businessId: b};
    return ids.map((id) => byId[id]).whereType<BusinessDto>().toList();
  } catch (_) {
    // Fallback: limited parallel fetch if batch endpoint unavailable
    const chunk = 4;
    final out = <BusinessDto>[];
    for (var i = 0; i < ids.length; i += chunk) {
      final slice = ids.skip(i).take(chunk);
      final part = await Future.wait(slice.map((id) async {
        try {
          return await repo.getBusinessById(id);
        } catch (_) {
          return null;
        }
      }));
      out.addAll(part.whereType<BusinessDto>());
    }
    return out;
  }
});

final singleBusinessProvider = FutureProvider.family<BusinessDto, int>((ref, id) async {
  final repo = ref.watch(businessRepositoryProvider);
  return await repo.getBusinessById(id);
});

final allBusinessesProvider = FutureProvider<List<BusinessDto>>((ref) async {
  final repo = ref.watch(businessRepositoryProvider);
  return await repo.getAllBusinesses();
});

// Fetch specific business metrics provider
final businessMetricsProvider = FutureProvider.family<Map<String, int>, int>((ref, businessId) async {
  ref.watch(authProvider); // Reset metric values if authentication state changes
  try {
    final response = await DioClient().dio.get('analytics/business/$businessId');
    final data = response.data;
    if (data != null && data['success'] == true) {
      final metrics = data['data'];
      return {
        'views': (metrics['views'] as num?)?.toInt() ?? 0,
        'favorites': (metrics['favorites'] as num?)?.toInt() ?? 0,
        'clicks': (metrics['clicks'] as num?)?.toInt() ?? 0,
      };
    }
  } catch (_) {}
  return {'views': 0, 'favorites': 0, 'clicks': 0};
});
