import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../data/models/business_models.dart';
import '../data/repositories/business_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/auth_state.dart';
import '../../auth/providers/user_provider.dart';

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
    ref.invalidate(searchResultsProvider);
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

  SearchQueryState({
    this.query = '',
    this.selectedCategoryId,
    this.selectedSubcategoryId,
    this.latitude,
    this.longitude,
    this.isVoiceSearch = false,
    this.sortBy = 'distance',
    this.userPincode = '',
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
  void setCategory(int? id) => state = state.copyWith(selectedCategoryId: id, clearSubcategory: true, isVoiceSearch: false);
  void setSubcategory(int? subId) => state = state.copyWith(selectedSubcategoryId: subId, isVoiceSearch: false);
  void clearCategory() => state = state.copyWith(clearCategory: true, clearSubcategory: true, isVoiceSearch: false);
  void clearSubcategory() => state = state.copyWith(clearSubcategory: true, isVoiceSearch: false);
  void setLocation(double lat, double lng) => state = state.copyWith(latitude: lat, longitude: lng);
  void setSortBy(String sort) => state = state.copyWith(sortBy: sort);
  void setPincode(String pin) => state = state.copyWith(userPincode: pin);
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, SearchQueryState>(
  SearchQueryNotifier.new,
);

extension BusinessDtoExtension on BusinessDto {
  String get ownerName {
    final names = [
      'Pandit Rajesh Sharma',
      'Acharya Vinay Shastri',
      'Shri Ramesh Upadhyay',
      'Pandit Anand Dwivedi',
      'Shri Krishna Gopal',
      'Acharya Devendra Prasad',
      'Smt. Radha Mangal',
      'Shri Suresh Kulkarni',
      'Pandit Harish Vyas',
      'Shri Ramakant Joshi',
    ];
    return names[businessId % names.length];
  }
}

// Search results provider based on query state
final searchResultsProvider = FutureProvider<List<BusinessDto>>((ref) async {
  final queryState = ref.watch(searchQueryProvider);
  final repo = ref.watch(businessRepositoryProvider);

  String resolvedPincode = queryState.userPincode;
  String resolvedCity = '';
  try {
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.value;
    if (profile != null) {
      if (resolvedPincode.isEmpty && profile.address.pincode != null) {
        resolvedPincode = profile.address.pincode!;
      }
      if (profile.address.city != null) {
        resolvedCity = profile.address.city!;
      }
    }
  } catch (_) {}

  List<BusinessDto> rawResults;
  if (queryState.isVoiceSearch && queryState.query.isNotEmpty) {
    rawResults = await repo.voiceSearchText(
      queryState.query,
      lat: queryState.latitude,
      lng: queryState.longitude,
    );
  } else {
    rawResults = await repo.searchBusinesses(
      queryState.query,
      latitude: queryState.latitude,
      longitude: queryState.longitude,
      sortBy: queryState.sortBy,
      userPincode: resolvedPincode,
      userCity: resolvedCity,
    );
  }

  // Fallback to all local listings if search query returns empty to test client ranking
  if (rawResults.isEmpty && queryState.query.trim().isNotEmpty) {
    try {
      rawResults = await repo.getAllBusinesses();
    } catch (_) {}
  }

  final searchWord = queryState.query.toLowerCase().trim();
  List<BusinessDto> filtered = rawResults;

  if (searchWord.isNotEmpty) {
    filtered = rawResults.where((b) {
      final nameMatch = b.businessName.toLowerCase().contains(searchWord);
      final ownerMatch = b.ownerName.toLowerCase().contains(searchWord);
      final catMatch = (b.categoryName ?? '').toLowerCase().contains(searchWord);
      final subMatch = (b.subcategoryName ?? '').toLowerCase().contains(searchWord);
      final descMatch = b.description.toLowerCase().contains(searchWord);
      final addressMatch = b.address.toLowerCase().contains(searchWord);
      final cityMatch = b.city.toLowerCase().contains(searchWord);
      final stateMatch = b.state.toLowerCase().contains(searchWord);
      final pinMatch = b.pincode.toLowerCase().contains(searchWord);

      bool zoneMatch = false;
      final lowerAddr = '${b.address} ${b.city} ${b.state}'.toLowerCase();
      if (searchWord.contains('east') && lowerAddr.contains('east')) zoneMatch = true;
      if (searchWord.contains('west') && lowerAddr.contains('west')) zoneMatch = true;
      if (searchWord.contains('north') && lowerAddr.contains('north')) zoneMatch = true;
      if (searchWord.contains('south') && lowerAddr.contains('south')) zoneMatch = true;
      if (searchWord.contains('central') && lowerAddr.contains('central')) zoneMatch = true;

      return nameMatch || ownerMatch || catMatch || subMatch || descMatch || addressMatch || cityMatch || stateMatch || pinMatch || zoneMatch;
    }).toList();
  }

  if (queryState.selectedCategoryId != null) {
    filtered = filtered.where((b) => b.categoryId == queryState.selectedCategoryId).toList();
    if (queryState.selectedSubcategoryId != null) {
      filtered = filtered.where((b) => b.subcategoryId == queryState.selectedSubcategoryId).toList();
    }
  }

  return filtered;
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
      } catch (_) {
        state = [...state, businessId]; // Rollback
      }
    } else {
      state = [...state, businessId];
      try {
        await repo.addFavorite(userId, businessId);
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
