import 'package:dio/dio.dart';
import '../models/user_profile.dart';

class UserRepository {
  final Dio dio;
  UserProfileDto? _cachedProfile;

  UserRepository({required this.dio});


  Future<UserProfileDto> getProfile() async {
    try {
      final response = await dio.get('user/profile');
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
      await dio.put('user/profile', data: dto.toJson());
      _cachedProfile = null;
    } on DioException catch (e) {
      final data = e.response?.data;
      String? msg;
      if (data is Map) {
        if (data['errors'] != null) {
          final errs = data['errors'];
          if (errs is Map) {
            final allMsgs = <String>[];
            errs.forEach((key, val) {
              if (val is List) {
                allMsgs.addAll(val.map((e) => e.toString()));
              } else {
                allMsgs.add(val.toString());
              }
            });
            if (allMsgs.isNotEmpty) {
              msg = allMsgs.join('\n');
            }
          }
        }
        msg ??= data['message']?.toString();
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

  Future<void> deleteAccount() async {
    try {
      await dio.delete('user/account');
      _cachedProfile = null;
    } on DioException catch (e) {
      final data = e.response?.data;
      String? msg;
      if (data is Map) {
        msg = data['message']?.toString();
      } else if (data is String && data.isNotEmpty) {
        msg = data;
      }
      msg ??= e.message ?? 'Failed to delete account';
      throw Exception(msg);
    }
  }
}
