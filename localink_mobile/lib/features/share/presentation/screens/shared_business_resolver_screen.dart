import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/app_error_formatter.dart';
import '../../../../core/storage/user_prefs_store.dart';
import '../../providers/share_provider.dart';
import '../../utils/pending_share_navigation.dart';

/// Resolves a single-business share token and opens the existing detail screen.
class SharedBusinessResolverScreen extends ConsumerStatefulWidget {
  final String publicToken;

  const SharedBusinessResolverScreen({super.key, required this.publicToken});

  @override
  ConsumerState<SharedBusinessResolverScreen> createState() =>
      _SharedBusinessResolverScreenState();
}

class _SharedBusinessResolverScreenState
    extends ConsumerState<SharedBusinessResolverScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserPrefsStore.markShareConsumed(
        PendingShareRoute(
          kind: ShareLinkKind.business,
          token: widget.publicToken,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final shareAsync = ref.watch(shareViewProvider(widget.publicToken));

    return Scaffold(
      body: shareAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF6600)),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppErrorFormatter.format(e),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => leaveShareScreen(context, ref),
                  child: const Text('Go home'),
                ),
              ],
            ),
          ),
        ),
        data: (share) {
          final available = share.items
              .where((i) => i.isAvailable && i.business != null)
              .toList();
          if (available.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'This business is no longer available.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => leaveShareScreen(context, ref),
                      child: const Text('Explore businesses'),
                    ),
                  ],
                ),
              ),
            );
          }

          final businessId = available.first.businessId;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.replace('/business-detail/$businessId');
            }
          });
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF6600)),
          );
        },
      ),
    );
  }
}
