import '../../../core/storage/user_prefs_store.dart';

/// GoRouter path for a pending share, or null if none stored.
Future<String?> pendingShareGoRoute() async {
  final pending = await UserPrefsStore.getPendingShare();
  if (pending == null) return null;
  await UserPrefsStore.clearPendingShare();
  switch (pending.kind) {
    case ShareLinkKind.business:
      return '/share/business/${pending.token}';
    case ShareLinkKind.collection:
      return '/share/collection/${pending.token}';
  }
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
