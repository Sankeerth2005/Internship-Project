import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/providers/auth_provider.dart';
import '../../../auth/providers/auth_state.dart';
import '../../../business/providers/business_provider.dart';
import '../../../business/data/models/business_models.dart';
import '../../../shared/presentation/widgets/app_back_button.dart';
import '../../../shared/presentation/widgets/app_feedback.dart';
import '../../../../core/network/app_error_formatter.dart';
import '../../../../core/storage/user_prefs_store.dart';
import '../../../../core/widgets/optimized_network_image.dart';
import '../../data/models/share_models.dart';
import '../../providers/share_provider.dart';
import '../../utils/pending_share_navigation.dart';

class _Tok {
  static const Color primary = Color(0xFFFF6600);
  static const Color bg = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFEAE8E3);
  static const Color textHigh = Color(0xFF1A1918);
  static const Color textMedium = Color(0xFF5F5C58);
  static const Color textLow = Color(0xFF9F9B96);
}

class SharedCollectionScreen extends ConsumerStatefulWidget {
  final String publicToken;

  const SharedCollectionScreen({super.key, required this.publicToken});

  @override
  ConsumerState<SharedCollectionScreen> createState() =>
      _SharedCollectionScreenState();
}

class _SharedCollectionScreenState
    extends ConsumerState<SharedCollectionScreen> {
  bool _savingAll = false;

  @override
  void initState() {
    super.initState();
    // Ensure this open is consumed even if splash/direct path skipped ShareResume.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserPrefsStore.markShareConsumed(
        PendingShareRoute(
          kind: ShareLinkKind.collection,
          token: widget.publicToken,
        ),
      );
    });
  }

  void _onBack() => leaveShareScreen(context, ref);

  @override
  Widget build(BuildContext context) {
    final shareAsync = ref.watch(shareViewProvider(widget.publicToken));
    final favorites = ref.watch(favoritesProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onBack();
      },
      child: Scaffold(
        backgroundColor: _Tok.bg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    AppBackButton(onPressed: _onBack),
                    const Expanded(
                      child: Text(
                        'Businesses Shared With You',
                        style: TextStyle(
                          color: _Tok.textHigh,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: shareAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: _Tok.primary),
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
                          style: const TextStyle(color: _Tok.textMedium),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => ref.invalidate(
                            shareViewProvider(widget.publicToken),
                          ),
                          child: const Text('Retry'),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _onBack,
                          child: const Text('Go back'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (share) {
                  if (share.items.isEmpty) {
                    return const Center(
                      child: Text(
                        'This shared list is empty.',
                        style: TextStyle(color: _Tok.textLow),
                      ),
                    );
                  }

                  final available = share.items
                      .where((i) => i.isAvailable && i.business != null)
                      .toList();
                  final missingCount = available
                      .where((i) => !favorites.contains(i.businessId))
                      .length;

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      if (share.sharedByDisplayName != null &&
                          share.sharedByDisplayName!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Shared by ${share.sharedByDisplayName}',
                            style: const TextStyle(
                              color: _Tok.textMedium,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      Text(
                        share.title,
                        style: const TextStyle(
                          color: _Tok.textHigh,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (share.note != null &&
                          share.note!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          share.note!,
                          style: const TextStyle(
                            color: _Tok.textMedium,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                      if (available.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _savingAll || missingCount == 0
                                ? null
                                : () => _saveAll(available),
                            style: FilledButton.styleFrom(
                              backgroundColor: _Tok.primary,
                              disabledBackgroundColor:
                                  _Tok.primary.withValues(alpha: 0.4),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: _savingAll
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.favorite_rounded, size: 18),
                            label: Text(
                              missingCount == 0
                                  ? 'All already in Favorites'
                                  : 'Save All to My Favorites ($missingCount)',
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      ...share.items.map((item) {
                        if (!item.isAvailable || item.business == null) {
                          return _UnavailableCard(
                            message: item.unavailableReason ??
                                'This business is no longer available.',
                          );
                        }
                        final already =
                            favorites.contains(item.businessId);
                        return _SharedBusinessRow(
                          business: item.business!,
                          alreadyInFavorites: already,
                          onView: () => context.push(
                            '/business-detail/${item.business!.businessId}',
                          ),
                          onSave: already
                              ? null
                              : () => _saveOne(item.businessId),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Future<void> _saveOne(int businessId) async {
    final auth = ref.read(authProvider);
    if (auth is! AuthAuthenticated) {
      AppFeedback.showWarning(context, 'Please sign in to save favorites.');
      return;
    }

    final favorites = ref.read(favoritesProvider);
    if (favorites.contains(businessId)) {
      AppFeedback.showInfo(context, 'Already in Favorites');
      return;
    }

    try {
      HapticFeedback.lightImpact();
      await ref.read(favoritesProvider.notifier).toggleFavorite(businessId);
      if (mounted) {
        AppFeedback.showSuccess(context, 'Saved to My Favorites');
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, AppErrorFormatter.format(e));
      }
    }
  }

  Future<void> _saveAll(List<SharedBusinessItem> available) async {
    final auth = ref.read(authProvider);
    if (auth is! AuthAuthenticated) {
      AppFeedback.showWarning(context, 'Please sign in to save favorites.');
      return;
    }

    setState(() => _savingAll = true);
    var added = 0;
    var skipped = 0;

    try {
      final notifier = ref.read(favoritesProvider.notifier);
      for (final item in available) {
        final current = ref.read(favoritesProvider);
        if (current.contains(item.businessId)) {
          skipped++;
          continue;
        }
        try {
          await notifier.toggleFavorite(item.businessId);
          added++;
        } catch (_) {
          // Continue remaining items; uniqueness is enforced server-side.
        }
      }

      if (!mounted) return;
      final total = available.length;
      AppFeedback.showSuccess(
        context,
        '$total businesses shared · $added added · $skipped already in Favorites',
      );
    } finally {
      if (mounted) setState(() => _savingAll = false);
    }
  }
}

class _SharedBusinessRow extends StatelessWidget {
  final BusinessDto business;
  final bool alreadyInFavorites;
  final VoidCallback onView;
  final VoidCallback? onSave;

  const _SharedBusinessRow({
    required this.business,
    required this.alreadyInFavorites,
    required this.onView,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F8F6),
        border: Border.all(color: _Tok.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: OptimizedNetworkImage.business(
                  imageUrl: business.photos.isNotEmpty
                      ? business.photos.first
                      : null,
                  width: 72,
                  height: 72,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.businessName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _Tok.textHigh,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((business.categoryName ?? '').trim().isNotEmpty)
                      Text(
                        business.categoryName ?? '',
                        style: const TextStyle(
                          color: _Tok.textLow,
                          fontSize: 12,
                        ),
                      ),
                    if (alreadyInFavorites) ...[
                      const SizedBox(height: 6),
                      const Text(
                        '✓ Already in Favorites',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onView,
                  child: const Text('View Business'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: alreadyInFavorites ? null : onSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: _Tok.primary,
                    disabledBackgroundColor: const Color(0xFFE8E6E1),
                    disabledForegroundColor: _Tok.textMedium,
                  ),
                  child: Text(
                    alreadyInFavorites ? 'Saved' : 'Add to Favorites',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UnavailableCard extends StatelessWidget {
  final String message;

  const _UnavailableCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: _Tok.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(color: _Tok.textMedium, fontSize: 13),
      ),
    );
  }
}
