import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/providers/auth_provider.dart';
import '../../../auth/providers/auth_state.dart';
import '../../../../core/auth/role_routes.dart';
import '../../../../core/storage/user_prefs_store.dart';
import '../../utils/pending_share_navigation.dart';
import '../../utils/share_link_listener.dart';

/// Navigates to a pending share once the user is fully authenticated.
class ShareResumeListener extends ConsumerStatefulWidget {
  final Widget child;

  const ShareResumeListener({super.key, required this.child});

  @override
  ConsumerState<ShareResumeListener> createState() =>
      _ShareResumeListenerState();
}

class _ShareResumeListenerState extends ConsumerState<ShareResumeListener> {
  StreamSubscription<void>? _sub;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _sub = ShareLinkEvents.stream.listen((_) => _tryNavigate());
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryNavigate());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      _tryNavigate();
    });
    return widget.child;
  }

  Future<void> _tryNavigate() async {
    if (_navigating || !mounted) return;
    final auth = ref.read(authProvider);
    if (auth is! AuthAuthenticated) return;
    if (auth.needsUserAgreement) return;
    if (auth.needsExperienceSelection &&
        !RoleRoutes.isAdmin(auth.userType)) {
      return;
    }

    final pending = await UserPrefsStore.getPendingShare();
    if (pending == null || !mounted) return;
    final route = shareRouteFor(pending);

    _navigating = true;
    try {
      final navContext = shareResumeNavigatorKey?.currentContext;
      if (navContext == null || !navContext.mounted) {
        // Not ready yet — keep pending for a later auth/frame retry.
        return;
      }
      final router = GoRouter.maybeOf(navContext);
      if (router == null) return;

      final current = router.state.uri.path;
      if (current == route) {
        await UserPrefsStore.markShareConsumed(pending);
        return;
      }

      router.go(route);
      await UserPrefsStore.markShareConsumed(pending);
    } catch (e) {
      debugPrint('ShareResumeListener navigate failed: $e');
    } finally {
      _navigating = false;
    }
  }
}

/// Bound from main.dart so navigation works from MaterialApp.builder.
GlobalKey<NavigatorState>? shareResumeNavigatorKey;

void bindShareResumeNavigatorKey(GlobalKey<NavigatorState> key) {
  shareResumeNavigatorKey = key;
}
