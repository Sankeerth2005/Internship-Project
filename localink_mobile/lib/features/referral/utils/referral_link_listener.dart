import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import '../../../core/storage/user_prefs_store.dart';

/// Captures invite deep links / custom scheme and stores a pending referral code.
///
/// Supported examples:
/// - https://vocalforsanatan.com/invite?code=K7M2NP
/// - vocalforsanatan://invite?code=K7M2NP
/// - Legacy: …?code=VFS-K7M2NP (still accepted)
///
/// Deferred install attribution is best-effort via the website Play referrer /
/// localStorage handoff — not guaranteed without a commercial MMP.
class ReferralLinkListener {
  ReferralLinkListener._();

  static final AppLinks _appLinks = AppLinks();
  static bool _started = false;

  static Future<void> start() async {
    if (_started) return;
    _started = true;

    try {
      final initial = await _appLinks.getInitialLink();
      await _capture(initial);
    } catch (e) {
      debugPrint('ReferralLinkListener initial link failed: $e');
    }

    _appLinks.uriLinkStream.listen(
      (uri) async {
        await _capture(uri);
      },
      onError: (Object e) {
        debugPrint('ReferralLinkListener stream error: $e');
      },
    );
  }

  static Future<void> _capture(Uri? uri) async {
    if (uri == null) return;
    final code = extractCode(uri);
    if (code == null) return;
    await UserPrefsStore.setPendingReferralCode(code);
    debugPrint('Pending referral code captured: $code');
  }

  /// Visible for tests.
  static String? extractCode(Uri uri) {
    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();
    final isInviteHttps = (host == 'vocalforsanatan.com' ||
            host == 'www.vocalforsanatan.com') &&
        path.startsWith('/invite');
    final isCustom = uri.scheme == 'vocalforsanatan' &&
        (host == 'invite' || path.contains('invite'));

    if (!isInviteHttps && !isCustom) {
      // Also accept bare query on custom scheme without host.
      if (uri.scheme != 'vocalforsanatan') return null;
    }

    final fromQuery = uri.queryParameters['code']?.trim();
    if (fromQuery != null && fromQuery.isNotEmpty) {
      return _normalizeCode(fromQuery);
    }

    // Path style: /invite/K7M2NP
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length >= 2 &&
        segments[0].toLowerCase() == 'invite' &&
        segments[1].isNotEmpty) {
      return _normalizeCode(segments[1]);
    }

    return null;
  }

  /// Uppercase + strip legacy `VFS-` prefix for consistent pending storage.
  static String _normalizeCode(String raw) {
    var code = raw.trim().toUpperCase();
    if (code.startsWith('VFS-')) {
      code = code.substring(4);
    }
    return code;
  }
}
