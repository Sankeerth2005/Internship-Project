import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/business_provider.dart';
import '../../data/models/business_models.dart';
import '../../../../core/network/dio_client.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final allBusinessesAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                children: [
                  const Icon(Icons.favorite, color: Color(0xFFC8A97E), size: 24),
                  const SizedBox(width: 10),
                  const Text(
                    'My Favorites',
                    style: TextStyle(color: Color(0xFFC8A97E), fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (favorites.isNotEmpty)
                    Text(
                      '${favorites.length} saved',
                      style: const TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: allBusinessesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFC8A97E))),
                error: (err, st) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                      const SizedBox(height: 12),
                      Text('Error: $err', style: const TextStyle(color: Colors.white54), textAlign: TextAlign.center),
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
                            Icon(Icons.favorite_border, color: Colors.white.withValues(alpha: 0.15), size: 80),
                            const SizedBox(height: 20),
                            const Text(
                              'No Favorites Yet',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Start exploring and add businesses you love!',
                              style: TextStyle(color: Colors.white38, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: favoriteBusinesses.length,
                    itemBuilder: (context, index) {
                      final business = favoriteBusinesses[index];
                      return _buildFavoriteCard(context, ref, business);
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

  Widget _buildFavoriteCard(BuildContext context, WidgetRef ref, BusinessDto business) {
    return GestureDetector(
      onTap: () => context.push('/business-detail/${business.businessId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E).withValues(alpha: 0.8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              // Image
              SizedBox(
                width: 110,
                height: 110,
                child: business.photos.isNotEmpty
                    ? Image.network(
                        '${Uri.parse(DioClient().dio.options.baseUrl).origin}${business.photos.first}',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, st) => Container(
                          color: const Color(0xFF2A2A2A),
                          child: const Icon(Icons.store, color: Color(0xFFC8A97E), size: 30),
                        ),
                      )
                    : Container(
                        color: const Color(0xFF2A2A2A),
                        child: const Icon(Icons.store, color: Color(0xFFC8A97E), size: 30),
                      ),
              ),

              // Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        business.businessName,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (business.categoryName != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          business.categoryName!,
                          style: const TextStyle(color: Color(0xFFC8A97E), fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        business.description,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Color(0xFFC8A97E), size: 14),
                          const SizedBox(width: 3),
                          Text(
                            business.averageRating.toStringAsFixed(1),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Color(0xFFC8A97E), size: 12),
                              const SizedBox(width: 2),
                              Text(
                                business.city,
                                style: const TextStyle(color: Colors.white38, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Remove button
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.redAccent, size: 22),
                  onPressed: () {
                    ref.read(favoritesProvider.notifier).toggleFavorite(business.businessId);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
