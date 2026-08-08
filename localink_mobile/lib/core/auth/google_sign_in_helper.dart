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

  static GoogleSignIn _client() {
    final webClientId = AppConfig.googleWebClientId;
    if (webClientId.isEmpty) {
      throw StateError(
        'Google Sign-In is not configured. Rebuild with GOOGLE_WEB_CLIENT_ID.',
      );
    }

    return GoogleSignIn(
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

      // ApiException: 10 = DEVELOPER_ERROR
      if (code == 'sign_in_failed' &&
          (message.contains('10:') || message.contains(': 10'))) {
        return 'Google Sign-In is misconfigured (error 10).\n'
            'In Google Cloud Console create an Android OAuth client with:\n'
            '• Package: com.vocalforsanatan.app\n'
            '• SHA-1: 92:BB:BD:1C:6F:D4:B6:AF:57:FB:2C:AA:C3:F6:48:61:08:70:EB:C2\n'
            'Same project as the Web client ID. Wait a few minutes, then retry.';
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
