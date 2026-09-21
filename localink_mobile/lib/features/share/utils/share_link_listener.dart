import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import '../../../core/storage/user_prefs_store.dart';

/// Fired when a share deep link is captured (for in-app resume navigation).
class ShareLinkEvents {
  ShareLinkEvents._();

  static final StreamController<void> _controller =
      StreamController<void>.broadcast();

  static Stream<void> get stream => _controller.stream;

  static void notifyCaptured() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }
}

/// Captures business/collection share deep links and stores pending navigation.
class ShareLinkListener {
  ShareLinkListener._();

  static final AppLinks _appLinks = AppLinks();
  static bool _started = false;

  static Future<void> start() async {
    if (_started) return;
    _started = true;

    try {
      final initial = await _appLinks.getInitialLink();
      await _capture(initial);
    } catch (e) {
      debugPrint('ShareLinkListener initial link failed: $e');
    }

    _appLinks.uriLinkStream.listen(
      (uri) async {
        await _capture(uri);
      },
      onError: (Object e) {
        debugPrint('ShareLinkListener stream error: $e');
      },
    );
  }

  static Future<void> _capture(Uri? uri) async {
    if (uri == null) return;
    final pending = extractPending(uri);
    if (pending == null) return;
    await UserPrefsStore.setPendingShare(pending, force: true);
    ShareLinkEvents.notifyCaptured();
    debugPrint('Pending share captured: ${pending.kind}/${pending.token}');
  }

  /// Visible for tests.
  ///
  /// Accepts:
  /// - https://vocalforsanatan.com/share/collection/TOKEN
  /// - vocalforsanatan://share/collection/TOKEN
  /// - path-only /share/collection/TOKEN (GoRouter / App Link cold start)
  static PendingShareRoute? extractPending(Uri uri) {
    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

    final isHttpsShare = (host == 'vocalforsanatan.com' ||
            host == 'www.vocalforsanatan.com') &&
        path.startsWith('/share');
    final isCustomShare = uri.scheme == 'vocalforsanatan' &&
        (host == 'share' || path.contains('share'));
    // GoRouter often delivers only the path when handling App Links.
    final isPathOnlyShare =
        (uri.scheme.isEmpty ||
            uri.scheme == 'https' ||
            uri.scheme == 'http' ||
            host.isEmpty) &&
        path.startsWith('/share/');

    if (!isHttpsShare && !isCustomShare && !isPathOnlyShare) return null;

    if (segments.length >= 3 && segments[0].toLowerCase() == 'share') {
      final kindRaw = segments[1].toLowerCase();
      final token = segments[2].trim().toUpperCase();
      if (token.isEmpty) return null;
      if (kindRaw == 'business') {
        return PendingShareRoute(kind: ShareLinkKind.business, token: token);
      }
      if (kindRaw == 'collection') {
        return PendingShareRoute(kind: ShareLinkKind.collection, token: token);
      }
    }

    // vocalforsanatan://share/business/TOKEN
    if (uri.scheme == 'vocalforsanatan' &&
        host == 'share' &&
        segments.length >= 2) {
      final kindRaw = segments[0].toLowerCase();
      final token = segments[1].trim().toUpperCase();
      if (token.isEmpty) return null;
      if (kindRaw == 'business') {
        return PendingShareRoute(kind: ShareLinkKind.business, token: token);
      }
      if (kindRaw == 'collection') {
        return PendingShareRoute(kind: ShareLinkKind.collection, token: token);
      }
    }

    return null;
  }

  /// Maps public share paths to in-app routes.
  static String? appRouteForUri(Uri uri) {
    final pending = extractPending(uri);
    if (pending == null) return null;
    switch (pending.kind) {
      case ShareLinkKind.business:
        return '/share/business/${pending.token}';
      case ShareLinkKind.collection:
        return '/share/collection/${pending.token}';
    }
  }
}
