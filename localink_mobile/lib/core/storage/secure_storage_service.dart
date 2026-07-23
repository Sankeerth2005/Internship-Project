import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _tokenKey = 'jwt_token';
  static const _userTypeKey = 'user_type';
  static const _userIdKey = 'user_id';

  static Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (e) {
      debugPrint('SecureStorageService: Error writing token: $e');
    }
  }

  static Future<String?> getToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      debugPrint('SecureStorageService: Error reading token: $e. Clearing storage.');
      await clearAll();
      return null;
    }
  }

  static Future<void> deleteToken() async {
    try {
      await _storage.delete(key: _tokenKey);
    } catch (e) {
      debugPrint('SecureStorageService: Error deleting token: $e');
    }
  }

  static Future<void> saveUserType(String userType) async {
    try {
      await _storage.write(key: _userTypeKey, value: userType);
    } catch (e) {
      debugPrint('SecureStorageService: Error writing userType: $e');
    }
  }

  static Future<String?> getUserType() async {
    try {
      return await _storage.read(key: _userTypeKey);
    } catch (e) {
      debugPrint('SecureStorageService: Error reading userType: $e. Clearing storage.');
      await clearAll();
      return null;
    }
  }

  static Future<void> saveUserId(int userId) async {
    try {
      await _storage.write(key: _userIdKey, value: userId.toString());
    } catch (e) {
      debugPrint('SecureStorageService: Error writing userId: $e');
    }
  }

  static Future<int?> getUserId() async {
    try {
      final val = await _storage.read(key: _userIdKey);
      return val != null ? int.tryParse(val) : null;
    } catch (e) {
      debugPrint('SecureStorageService: Error reading userId: $e. Clearing storage.');
      await clearAll();
      return null;
    }
  }

  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('SecureStorageService: Error deleting all: $e');
    }
  }
}
