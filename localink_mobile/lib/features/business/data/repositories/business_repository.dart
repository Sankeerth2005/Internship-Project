import 'package:dio/dio.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/business_models.dart';

class BusinessRepository {
  final Dio _dio;

  // ignore: prefer_initializing_formals
  BusinessRepository({required Dio dio}) : _dio = dio;

  Future<Options> _getAuthOptions() async {
    final token = await SecureStorageService.getToken();
    return Options(
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }

  // CACHE VARIABLES
  List<CategoryDto>? _cachedCategories;
  final Map<int, List<SubcategoryDto>> _cachedSubcategories = {};

  // CATEGORIES
  Future<List<CategoryDto>> getCategories() async {
    if (_cachedCategories != null) return _cachedCategories!;
    final response = await _dio.get('categories');
    final list = response.data as List? ?? [];
    _cachedCategories = list.map((e) => CategoryDto.fromJson(e)).toList();
    return _cachedCategories!;
  }

  // SUBCATEGORIES
  Future<List<SubcategoryDto>> getSubcategories(int categoryId) async {
    if (_cachedSubcategories.containsKey(categoryId)) return _cachedSubcategories[categoryId]!;
    final response = await _dio.get('categories/$categoryId/subcategories');
    final list = response.data as List? ?? [];
    _cachedSubcategories[categoryId] = list.map((e) => SubcategoryDto.fromJson(e)).toList();
    return _cachedSubcategories[categoryId]!;
  }

  // SEARCH BUSINESSES
  Future<List<BusinessDto>> searchBusinesses(
    String query, {
    double? latitude,
    double? longitude,
  }) async {
    final response = await _dio.get(
      'business/search',
      queryParameters: {'query': query},
      options: Options(
        headers: {
          if (latitude != null) 'X-User-Latitude': latitude.toString(),
          if (longitude != null) 'X-User-Longitude': longitude.toString(),
        },
      ),
    );
    final list = response.data as List? ?? [];
    return list.map((e) => BusinessDto.fromJson(e)).toList();
  }

  // GET ALL BUSINESSES
  Future<List<BusinessDto>> getAllBusinesses() async {
    final response = await _dio.get('business');
    final list = response.data as List? ?? [];
    return list.map((e) => BusinessDto.fromJson(e)).toList();
  }

  // GET BUSINESS BY ID
  Future<BusinessDto> getBusinessById(int id) async {
    final response = await _dio.get('business/$id');
    return BusinessDto.fromJson(response.data);
  }

  // GET OWNED BUSINESSES (Dashboard)
  Future<List<BusinessDto>> getMyBusinesses() async {
    final options = await _getAuthOptions();
    final response = await _dio.get('business/my-businesses', options: options);
    final list = response.data as List? ?? [];
    return list.map((e) => BusinessDto.fromJson(e)).toList();
  }

  // REGISTER BUSINESS
  Future<int> registerBusiness(BusinessDto business) async {
    final options = await _getAuthOptions();
    final response = await _dio.post(
      'business/register',
      data: business.toJson(),
      options: options,
    );
    return response.data['businessId'] as int;
  }

  // UPDATE BUSINESS
  Future<bool> updateBusiness(int id, BusinessDto business) async {
    final options = await _getAuthOptions();
    final payload = {
      'businessName': business.businessName,
      'description': business.description,
      'categoryId': business.categoryId,
      'subcategoryId': business.subcategoryId,
      'phoneCode': business.phoneCode,
      'phoneNumber': business.phoneNumber,
      'email': business.email,
      'city': business.city,
      'streetAddress': business.address,
      'state': business.state,
      'country': business.country,
      'pincode': business.pincode,
      'photo': business.photo,
      'hours': business.hours.map((h) => h.toJson()).toList(),
    };
    final response = await _dio.put(
      'business/$id',
      data: payload,
      options: options,
    );
    return response.data['success'] == true;
  }

  // ADD REVIEW
  Future<void> addReview(int businessId, double rating, String comment) async {
    final options = await _getAuthOptions();
    await _dio.post(
      'reviews',
      data: {
        'businessId': businessId,
        'rating': rating.toInt(),
        'comment': comment,
      },
      options: options,
    );
  }

  // GET REVIEWS BY BUSINESS
  Future<List<BusinessReviewDto>> getReviews(int businessId) async {
    final response = await _dio.get('reviews/business/$businessId');
    final list = response.data as List? ?? [];
    return list.map((e) => BusinessReviewDto.fromJson(e)).toList();
  }

  // VOICE SEARCH (text-based — STT happens on device)
  Future<List<BusinessDto>> voiceSearchText(
    String query, {
    bool openNow = false,
    int radius = 5,
    String? category,
    double? lat,
    double? lng,
  }) async {
    final response = await _dio.post(
      'search/voice',
      data: {
        'query': query,
        'openNow': openNow,
        'radius': radius,
        'category': category,
        'language': 'en',
      },
      options: Options(
        headers: {
          if (lat != null) 'X-User-Latitude': lat.toString(),
          if (lng != null) 'X-User-Longitude': lng.toString(),
        },
      ),
    );
    final results = response.data['results'] as List? ?? [];
    return results.map((e) => BusinessDto.fromJson(e)).toList();
  }

  // ─── FAVORITES ───
  Future<List<int>> getFavorites(int userId) async {
    final response = await _dio.get('Favorites/user/$userId');
    final list = response.data as List? ?? [];
    return list.map<int>((e) => (e as num).toInt()).toList();
  }

  Future<void> addFavorite(int userId, int businessId) async {
    await _dio.post('Favorites/add', data: {
      'userId': userId,
      'businessId': businessId,
    });
  }

  Future<void> removeFavorite(int userId, int businessId) async {
    await _dio.delete('Favorites/remove', queryParameters: {
      'userId': userId,
      'businessId': businessId,
    });
  }

  // ─── AI REVIEW ───
  Future<List<String>> getReviewSuggestions(
    String draftText,
    int rating,
    String businessName,
  ) async {
    final options = await _getAuthOptions();
    final response = await _dio.post(
      'ai/review-suggestions',
      data: {
        'draftText': draftText,
        'rating': rating,
        'businessName': businessName,
      },
      options: options,
    );
    if (response.data['success'] == true) {
      final data = response.data['data'];
      if (data is List) {
        return data.map<String>((e) => e.toString()).toList();
      } else if (data is String) {
        return [data];
      }
    }
    return [];
  }

  Future<String> getReviewSummary(
    List<String> reviews,
    double averageRating,
    int totalReviews,
    String businessName,
  ) async {
    final response = await _dio.post(
      'ai/review-summary',
      data: {
        'reviews': reviews,
        'averageRating': averageRating,
        'totalReviews': totalReviews,
        'businessName': businessName,
      },
    );
    if (response.data['success'] == true) {
      return response.data['data']?.toString() ?? '';
    }
    return '';
  }
}
