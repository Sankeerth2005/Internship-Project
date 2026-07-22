import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/business_provider.dart';
import '../../../favorites/widgets/favorite_business_card.dart';

class _FavTok {
  static const Color primary = Color(0xFFFF6600);
  static const Color bg = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFEAE8E3);
  static const Color textHigh = Color(0xFF1A1918);
  static const Color textMedium = Color(0xFF5F5C58);
  static const Color textLow = Color(0xFF9F9B96);
}

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedCollection = 'All';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);
    final allBusinessesAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      backgroundColor: _FavTok.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.favorite_rounded, color: _FavTok.primary, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Favorites',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: _FavTok.textHigh,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
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
                            style: const TextStyle(
                              color: _FavTok.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Search local favorites input field
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1A1918).withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (val) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search within favorites...',
                        hintStyle: const TextStyle(color: _FavTok.textLow, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: _FavTok.primary, size: 18),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: _FavTok.textMedium, size: 16),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        fillColor: const Color(0xFFF9F8F6),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _FavTok.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _FavTok.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _FavTok.primary, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: allBusinessesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: _FavTok.primary)),
                error: (err, st) => Center(
                  child: Text('Error: $err', style: const TextStyle(color: _FavTok.textMedium)),
                ),
                data: (businesses) {
                  // Get favorited businesses
                  final favList = businesses.where((b) => favorites.contains(b.businessId)).toList();

                  if (favList.isEmpty) {
                    return _buildEmptyState();
                  }

                  // Dynamically extract unique categories of favorites for Collections
                  final collections = ['All'];
                  for (final b in favList) {
                    final catName = b.categoryName ?? 'Other';
                    if (!collections.contains(catName)) {
                      collections.add(catName);
                    }
                  }

                  // Reset selected collection if it's no longer present
                  if (!collections.contains(_selectedCollection)) {
                    _selectedCollection = 'All';
                  }

                  // Apply search query filter and collection filter client-side
                  final query = _searchCtrl.text.toLowerCase().trim();
                  final filteredFavs = favList.where((b) {
                    final matchesCollection = _selectedCollection == 'All' ||
                        (b.categoryName ?? 'Other') == _selectedCollection;
                    final matchesQuery = query.isEmpty ||
                        b.businessName.toLowerCase().contains(query) ||
                        b.address.toLowerCase().contains(query) ||
                        (b.categoryName ?? '').toLowerCase().contains(query);
                    return matchesCollection && matchesQuery;
                  }).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Collections Horizontal Selector Row
                      SizedBox(
                        height: 46,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: collections.length,
                          itemBuilder: (context, idx) {
                            final colName = collections[idx];
                            final isSelected = colName == _selectedCollection;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _selectedCollection = colName;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? _FavTok.primary : const Color(0xFFF9F8F6),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? _FavTok.primary : _FavTok.border,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    colName,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : _FavTok.textMedium,
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Listing view
                      Expanded(
                        child: filteredFavs.isEmpty
                            ? Center(
                                child: Text(
                                  'No favorites match your filters',
                                  style: TextStyle(color: _FavTok.textLow, fontSize: 13),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                itemCount: filteredFavs.length,
                                itemBuilder: (context, index) {
                                  final business = filteredFavs[index];
                                  return TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0.0, end: 1.0),
                                    duration: Duration(milliseconds: 200 + (index * 40).clamp(0, 260)),
                                    builder: (context, val, child) {
                                      return Opacity(
                                        opacity: val,
                                        child: Transform.translate(
                                          offset: Offset(0, 16 * (1 - val)),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: FavoriteBusinessCard(
                                        business: business,
                                        onRemove: () {
                                          HapticFeedback.mediumImpact();
                                          ref.read(favoritesProvider.notifier).toggleFavorite(business.businessId);
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border_rounded, color: _FavTok.textLow, size: 72),
            const SizedBox(height: 16),
            const Text(
              'No Favorites Saved',
              style: TextStyle(
                color: _FavTok.textHigh,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Explore neighborhood listings and click the heart icon to save them here.',
              style: TextStyle(color: _FavTok.textMedium, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
