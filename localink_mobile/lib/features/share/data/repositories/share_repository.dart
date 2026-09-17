import 'package:dio/dio.dart';
import '../models/share_models.dart';

class ShareRepository {
  final Dio dio;

  ShareRepository({required this.dio});

  Future<ShareCreatedResult> createBusinessShare(int businessId) async {
    final response = await dio.post(
      'shares/business',
      data: {'businessId': businessId},
    );
    return _parseCreated(response.data);
  }

  Future<ShareCreatedResult> createFavoritesShare({
    required bool shareAllFavorites,
    List<int>? businessIds,
    String? title,
    String? note,
  }) async {
    final response = await dio.post(
      'shares/favorites',
      data: {
        'shareAllFavorites': shareAllFavorites,
        if (businessIds != null) 'businessIds': businessIds,
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
    return _parseCreated(response.data);
  }

  Future<BusinessShareView> getShare(String publicToken) async {
    try {
      final response = await dio.get('shares/$publicToken');
      final body = response.data;
      if (body is Map && body['success'] == true && body['data'] is Map) {
        return BusinessShareView.fromJson(
          Map<String, dynamic>.from(body['data'] as Map),
        );
      }
      throw Exception(
        (body is Map ? body['message'] : null)?.toString() ?? 'Share not found',
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        throw Exception(data['message'].toString());
      }
      throw Exception(e.message ?? 'Failed to load share');
    }
  }

  ShareCreatedResult _parseCreated(dynamic body) {
    if (body is Map && body['success'] == true && body['data'] is Map) {
      return ShareCreatedResult.fromJson(
        Map<String, dynamic>.from(body['data'] as Map),
      );
    }
    throw Exception(
      (body is Map ? body['message'] : null)?.toString() ??
          'Failed to create share',
    );
  }
}
