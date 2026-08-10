import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const _tokenKey = 'jwt_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userTypeKey = 'user_type';
  static const _userIdKey = 'user_id';
  static const _activeExperienceKey = 'active_experience';

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
      debugPrint('SecureStorageService: Error reading token: $e');
      return null;
    }
  }

  static Future<void> saveRefreshToken(String refreshToken) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    } catch (e) {
      debugPrint('SecureStorageService: Error writing refresh token: $e');
    }
  }

  static Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      debugPrint('SecureStorageService: Error reading refresh token: $e');
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

  static Future<void> deleteRefreshToken() async {
    try {
      await _storage.delete(key: _refreshTokenKey);
    } catch (e) {
      debugPrint('SecureStorageService: Error deleting refresh token: $e');
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
      debugPrint('SecureStorageService: Error reading userType: $e');
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
      debugPrint('SecureStorageService: Error reading userId: $e');
      return null;
    }
  }

  /// Persisted post-auth experience for this device session ("user" | "businessowner").
  static Future<void> saveActiveExperience(String experience) async {
    try {
      await _storage.write(key: _activeExperienceKey, value: experience);
    } catch (e) {
      debugPrint('SecureStorageService: Error writing activeExperience: $e');
    }
  }

  static Future<String?> getActiveExperience() async {
    try {
      return await _storage.read(key: _activeExperienceKey);
    } catch (e) {
      debugPrint('SecureStorageService: Error reading activeExperience: $e');
      return null;
    }
  }

  static Future<void> clearActiveExperience() async {
    try {
      await _storage.delete(key: _activeExperienceKey);
    } catch (e) {
      debugPrint('SecureStorageService: Error clearing activeExperience: $e');
    }
  }

  /// Clears only auth-related keys (keeps other secure prefs intact).
  static Future<void> clearAuth() async {
    try {
      await Future.wait([
        _storage.delete(key: _tokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _userTypeKey),
        _storage.delete(key: _userIdKey),
        _storage.delete(key: _activeExperienceKey),
      ]);
    } catch (e) {
      debugPrint('SecureStorageService: Error clearing auth: $e');
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
