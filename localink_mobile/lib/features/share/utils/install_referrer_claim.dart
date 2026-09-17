import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:play_install_referrer/play_install_referrer.dart';

import '../../../core/storage/user_prefs_store.dart';
import 'share_link_listener.dart';

/// Best-effort Play Install Referrer claim for share + referral deep links.
///
/// Website formats:
/// - Share: utm_source=share&utm_content=business_TOKEN or collection_TOKEN
/// - Invite: utm_source=referral&utm_content=CODE
///
/// Does NOT credit referrals from share links. Referral pending is only set when
/// utm_source=referral (registration attribution stays separate).
class InstallReferrerClaim {
  InstallReferrerClaim._();

  static Future<void> claimOnce() async {
    if (kIsWeb) return;
    try {
      if (!Platform.isAndroid) return;
    } catch (_) {
      return;
    }

    if (await UserPrefsStore.hasClaimedInstallReferrer()) return;

    try {
      final details = await PlayInstallReferrer.installReferrer;
      final raw = details.installReferrer;
      if (raw != null && raw.trim().isNotEmpty) {
        await applyReferrerString(raw);
      }
    } catch (e) {
      debugPrint('InstallReferrerClaim failed: $e');
    } finally {
      // Mark claimed even on failure so we don't hammer the API every launch.
      await UserPrefsStore.markInstallReferrerClaimed();
    }
  }

  /// Visible for tests — parses a Play referrer query string.
  static Future<void> applyReferrerString(String raw) async {
    final params = _parseReferrerParams(raw);
    final source = (params['utm_source'] ?? '').toLowerCase().trim();
    final content = (params['utm_content'] ?? '').trim();

    if (source == 'share' && content.isNotEmpty) {
      final pending = parseShareContent(content);
      if (pending != null) {
        await UserPrefsStore.setPendingShare(pending);
        ShareLinkEvents.notifyCaptured();
        debugPrint(
          'InstallReferrerClaim: pending share ${pending.kind}/${pending.token}',
        );
      }
      return;
    }

    if (source == 'referral' && content.isNotEmpty) {
      await UserPrefsStore.setPendingReferralCode(content);
      debugPrint('InstallReferrerClaim: pending referral code captured');
    }
  }

  /// `business_TOKEN` or `collection_TOKEN` from website utm_content.
  static PendingShareRoute? parseShareContent(String content) {
    final raw = content.trim();
    if (raw.isEmpty) return null;

    final sep = raw.indexOf('_');
    if (sep <= 0 || sep >= raw.length - 1) return null;

    final kindRaw = raw.substring(0, sep).toLowerCase();
    final token = raw.substring(sep + 1).trim().toUpperCase();
    if (token.length < 8 || token.length > 32) return null;
    if (!RegExp(r'^[A-Z2-9]+$').hasMatch(token)) return null;

    if (kindRaw == 'business') {
      return PendingShareRoute(kind: ShareLinkKind.business, token: token);
    }
    if (kindRaw == 'collection') {
      return PendingShareRoute(kind: ShareLinkKind.collection, token: token);
    }
    return null;
  }

  static Map<String, String> _parseReferrerParams(String raw) {
    final decoded = Uri.decodeQueryComponent(raw.trim());
    final params = <String, String>{};

    void absorb(String query) {
      for (final part in query.split('&')) {
        if (part.isEmpty) continue;
        final eq = part.indexOf('=');
        if (eq <= 0) continue;
        final key = Uri.decodeQueryComponent(part.substring(0, eq)).trim();
        final value = Uri.decodeQueryComponent(part.substring(eq + 1)).trim();
        if (key.isNotEmpty) params[key] = value;
      }
    }

    absorb(decoded);
    // Some Play payloads are double-encoded.
    if (!params.containsKey('utm_source') && decoded.contains('%')) {
      absorb(Uri.decodeQueryComponent(decoded));
    }
    return params;
  }
}
