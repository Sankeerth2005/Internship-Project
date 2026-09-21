import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/role_routes.dart';
import '../../../core/storage/user_prefs_store.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/auth_state.dart';

/// Peek pending share route without consuming (safe if navigation fails).
Future<String?> pendingShareGoRoute() async {
  final pending = await UserPrefsStore.getPendingShare();
  if (pending == null) return null;
  return shareRouteFor(pending);
}

/// Route to store when user must authenticate before opening a share.
String shareRouteFor(PendingShareRoute pending) {
  switch (pending.kind) {
    case ShareLinkKind.business:
      return '/share/business/${pending.token}';
    case ShareLinkKind.collection:
      return '/share/collection/${pending.token}';
  }
}

bool isShareDeepLinkPath(String location) {
  return location.startsWith('/share/business/') ||
      location.startsWith('/share/collection/') ||
      location.startsWith('/shared-business/') ||
      location.startsWith('/shared-collection/');
}

/// Marks the visible share screen as consumed (covers splash/direct open paths).
Future<void> markShareRouteConsumed(String location) async {
  final pending = pendingShareFromLocation(location);
  if (pending == null) return;
  await UserPrefsStore.markShareConsumed(pending);
}

PendingShareRoute? pendingShareFromLocation(String location) {
  final segments =
      Uri(path: location).pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty) return null;

  final root = segments[0].toLowerCase();

  if (root == 'share' && segments.length >= 3) {
    final kindRaw = segments[1].toLowerCase();
    final token = segments[2].trim().toUpperCase();
    if (token.isEmpty) return null;
    if (kindRaw == 'business') {
      return PendingShareRoute(kind: ShareLinkKind.business, token: token);
    }
    if (kindRaw == 'collection') {
      return PendingShareRoute(kind: ShareLinkKind.collection, token: token);
    }
    return null;
  }

  if (root == 'shared-collection' && segments.length >= 2) {
    final token = segments[1].trim().toUpperCase();
    if (token.isEmpty) return null;
    return PendingShareRoute(kind: ShareLinkKind.collection, token: token);
  }

  if (root == 'shared-business' && segments.length >= 2) {
    final token = segments[1].trim().toUpperCase();
    if (token.isEmpty) return null;
    return PendingShareRoute(kind: ShareLinkKind.business, token: token);
  }

  return null;
}

String postAuthOrWelcome(WidgetRef ref) {
  final auth = ref.read(authProvider);
  if (auth is AuthAuthenticated) {
    return RoleRoutes.resolvePostAuthRoute(
      accountType: auth.userType,
      activeExperience: auth.activeExperience,
      needsExperienceSelection: auth.needsExperienceSelection,
      needsUserAgreement: auth.needsUserAgreement,
    );
  }
  return '/welcome';
}

/// Leave Shared / share surfaces. Prefer [go] because share deep links use
/// [GoRouter.go] (empty stack), so [pop] often no-ops.
void leaveShareScreen(BuildContext context, WidgetRef ref) {
  if (!context.mounted) return;
  context.go(postAuthOrWelcome(ref));
}

/// Safe back for screens that may be root (deep link) or pushed.
void safeAppBack(BuildContext context, WidgetRef ref) {
  if (!context.mounted) return;
  if (context.canPop()) {
    context.pop();
    return;
  }
  context.go(postAuthOrWelcome(ref));
}
