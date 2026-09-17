import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/app_error_formatter.dart';
import '../../providers/share_provider.dart';

/// Resolves a single-business share token and opens the existing detail screen.
class SharedBusinessResolverScreen extends ConsumerWidget {
  final String publicToken;

  const SharedBusinessResolverScreen({super.key, required this.publicToken});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shareAsync = ref.watch(shareViewProvider(publicToken));

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
                  onPressed: () => context.go('/home'),
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
                      onPressed: () => context.go('/home'),
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
