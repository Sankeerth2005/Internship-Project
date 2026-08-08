import 'package:flutter/foundation.dart';

class AppConfig {
  /// Backend host without scheme, e.g. api.vocalforsanatan.com or ngrok host
  static const String backendHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: '127.0.0.1:5138',
  );

  static const bool useHttps = bool.fromEnvironment(
    'API_USE_HTTPS',
    defaultValue: false,
  );

  /// Allow HTTP release builds for LAN/manager testing only.
  static const bool allowInsecureRelease = bool.fromEnvironment(
    'API_ALLOW_INSECURE',
    defaultValue: false,
  );

  static String get geoapifyApiKey => const String.fromEnvironment(
    'GEOAPIFY_API_KEY',
    defaultValue: '',
  );

  /// Google OAuth web client ID (public client id — still injected at build time).
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  static bool get isConfigured => geoapifyApiKey.isNotEmpty;

  static bool get isLocalHost =>
      backendHost.startsWith('127.0.0.1') ||
      backendHost.startsWith('localhost') ||
      backendHost.startsWith('10.0.2.2');

  /// Release builds must not silently point at localhost.
  /// HTTPS is required unless API_ALLOW_INSECURE=true (manager LAN testing).
  static void assertReleaseReady() {
    if (kReleaseMode) {
      if (isLocalHost) {
        throw StateError(
          'Release build requires --dart-define=API_HOST=<api.vocalforsanatan.com or manager host>',
        );
      }
      if (!useHttps && !allowInsecureRelease) {
        throw StateError(
          'Release build requires --dart-define=API_USE_HTTPS=true '
          '(or API_ALLOW_INSECURE=true for temporary LAN testing)',
        );
      }
    }
  }
}
