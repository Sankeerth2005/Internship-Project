import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/business_provider.dart';
import '../../../favorites/widgets/favorite_business_card.dart';

// ─── DESIGN TOKENS ────────────────────────────────────────────────────────────
class _FavTok {
  static const Color primary = Color(0xFFFF6600);
  static const Color bg = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFEAE8E3);
  static const Color textHigh = Color(0xFF1A1918);
  static const Color textMedium = Color(0xFF5F5C58);
  static const Color textLow = Color(0xFF9F9B96);
}

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final allBusinessesAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      backgroundColor: _FavTok.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  const Icon(Icons.favorite_rounded, color: _FavTok.primary, size: 24),
                  const SizedBox(width: 10),
                  const Text(
                    'My Favorites',
                    style: TextStyle(color: _FavTok.textHigh, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (favorites.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _FavTok.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${favorites.length} saved',
                        style: const TextStyle(color: _FavTok.primary, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(color: _FavTok.border, height: 1),

            // Content
            Expanded(
              child: allBusinessesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: _FavTok.primary)),
                error: (err, st) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFE1251B), size: 48),
                      const SizedBox(height: 12),
                      Text('Error: $err', style: const TextStyle(color: _FavTok.textMedium), textAlign: TextAlign.center),
                    ],
                  ),
                ),
                data: (businesses) {
                  final favoriteBusinesses = businesses.where((b) => favorites.contains(b.businessId)).toList();

                  if (favoriteBusinesses.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.favorite_border_rounded, color: _FavTok.textLow, size: 80),
                            const SizedBox(height: 20),
                            const Text(
                              'No Favorites Yet',
                              style: TextStyle(color: _FavTok.textHigh, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Start exploring and add businesses you love!',
                              style: TextStyle(color: _FavTok.textMedium, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: favoriteBusinesses.length,
                    itemBuilder: (context, index) {
                      final business = favoriteBusinesses[index];
                      return TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 200 + (index * 50).clamp(0, 300)),
                        builder: (context, val, child) {
                          return Opacity(
                            opacity: val,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - val)),
                              child: child,
                            ),
                          );
                        },
                        child: FavoriteBusinessCard(
                          business: business,
                          onRemove: () {
                            ref.read(favoritesProvider.notifier).toggleFavorite(business.businessId);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
