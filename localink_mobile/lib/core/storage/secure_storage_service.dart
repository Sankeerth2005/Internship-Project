import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static const _tokenKey = 'jwt_token';
  static const _userTypeKey = 'user_type';
  static const _userIdKey = 'user_id';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  static Future<void> saveUserType(String userType) async {
    await _storage.write(key: _userTypeKey, value: userType);
  }

  static Future<String?> getUserType() async {
    return await _storage.read(key: _userTypeKey);
  }

  static Future<void> saveUserId(int userId) async {
    await _storage.write(key: _userIdKey, value: userId.toString());
  }

  static Future<int?> getUserId() async {
    final val = await _storage.read(key: _userIdKey);
    return val != null ? int.tryParse(val) : null;
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
