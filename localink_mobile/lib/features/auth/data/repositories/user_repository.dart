import 'package:dio/dio.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/user_profile.dart';

class UserRepository {
  final Dio dio;
  UserProfileDto? _cachedProfile;

  UserRepository({required this.dio});

  Future<Options> _getAuthOptions() async {
    final token = await SecureStorageService.getToken();
    return Options(
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }

  Future<UserProfileDto> getProfile() async {
    try {
      final options = await _getAuthOptions();
      final response = await dio.get('user/profile', options: options);
      _cachedProfile = UserProfileDto.fromJson(response.data);
      return _cachedProfile!;
    } on DioException catch (e) {
      final data = e.response?.data;
      String? msg;
      if (data is Map) {
        msg = data['message']?.toString();
      } else if (data is String && data.isNotEmpty) {
        msg = data;
      }
      msg ??= e.message ?? 'Failed to load profile';
      throw Exception(msg);
    }
  }

  Future<void> updateProfile(UpdateUserProfileDto dto) async {
    try {
      final options = await _getAuthOptions();
      await dio.put('user/profile', data: dto.toJson(), options: options);
      _cachedProfile = null;
    } on DioException catch (e) {
      final data = e.response?.data;
      String? msg;
      if (data is Map) {
        msg = data['message']?.toString();
      } else if (data is String && data.isNotEmpty) {
        msg = data;
      }
      msg ??= e.message ?? 'Failed to update profile';
      throw Exception(msg);
    }
  }

  void clearCache() {
    _cachedProfile = null;
  }
}
