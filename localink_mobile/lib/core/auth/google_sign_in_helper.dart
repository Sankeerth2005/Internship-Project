import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/app_config.dart';

/// Shared Google Sign-In for login / signup.
///
/// Uses the **Web** client ID as [GoogleSignIn.serverClientId] so the ID token
/// audience matches backend `GOOGLE_CLIENT_ID`.
/// The **Android** OAuth client (package + SHA-1) must exist in the same
/// Google Cloud project — it is not passed here.
class GoogleSignInHelper {
  GoogleSignInHelper._();

  static GoogleSignIn? _cached;

  static GoogleSignIn _client() {
    final webClientId = AppConfig.googleWebClientId.trim();
    if (webClientId.isEmpty) {
      throw StateError(
        'Google Sign-In is not configured. Rebuild with GOOGLE_WEB_CLIENT_ID.',
      );
    }
    if (!webClientId.endsWith('.apps.googleusercontent.com')) {
      throw StateError(
        'GOOGLE_WEB_CLIENT_ID looks invalid. Expected a Web OAuth client ID '
        'ending in .apps.googleusercontent.com.',
      );
    }

    final androidClientId = AppConfig.googleAndroidClientId.trim();
    if (androidClientId.isNotEmpty &&
        androidClientId.toLowerCase() == webClientId.toLowerCase()) {
      throw StateError(
        'GOOGLE_WEB_CLIENT_ID must be the Web OAuth client, not the Android '
        'client. Android OAuth clients are selected by package name + SHA-1.',
      );
    }

    return _cached ??= GoogleSignIn(
      scopes: const ['email', 'profile', 'openid'],
      serverClientId: webClientId,
      signInOption: SignInOption.standard,
    );
  }

  /// Returns a Google ID token, or `null` if the user cancelled.
  static Future<String?> getIdToken() async {
    final googleSignIn = _client();

    // Force account picker each time for predictable testing.
    try {
      await googleSignIn.signOut();
    } catch (_) {}

    final account = await googleSignIn.signIn();
    if (account == null) return null;

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError(
        'Google did not return an ID token. Confirm the Web client ID is set '
        'as serverClientId and matches backend GOOGLE_CLIENT_ID.',
      );
    }
    return idToken;
  }

  static String friendlyError(Object error) {
    if (error is PlatformException) {
      final code = error.code;
      final message = (error.message ?? '').toLowerCase();

      // ApiException: 10 = DEVELOPER_ERROR (package name / SHA-1 mismatch)
      if (code == 'sign_in_failed' &&
          (message.contains('10:') || message.contains(': 10'))) {
        return 'Google Sign-In is misconfigured (error 10).\n'
            'In Google Cloud Console → Credentials, create Android OAuth '
            'client(s) in the SAME project as the Web client ID:\n'
            '• Package name: com.vocalforsanatan.app\n'
            '• SHA-1 (Play App signing — required for Play Store): '
            'ED:D8:12:09:F5:16:C1:88:B4:64:82:56:1B:5A:C5:9A:B0:4F:49:F5\n'
            '• SHA-1 (upload / local release keystore): '
            '2D:A9:62:B5:59:B0:67:78:AE:2C:50:5D:04:37:02:F0:75:77:5D:5C\n'
            '• SHA-1 (debug / flutter run): '
            '92:BB:BD:1C:6F:D4:B6:AF:57:FB:2C:AA:C3:F6:48:61:08:70:EB:C2\n'
            'Create one Android client per SHA-1 if needed. '
            'Wait a few minutes, then retry.';
      }

      if (code == 'network_error') {
        return 'Network error during Google Sign-In. Check internet and try again.';
      }

      if (code == 'sign_in_canceled' || code == '12501') {
        return 'Google Sign-In was cancelled.';
      }

      return 'Google Sign-In failed ($code). ${error.message ?? ''}'.trim();
    }

    return error.toString().replaceFirst('Exception: ', '');
  }
}
