import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/business_provider.dart';
import '../../data/models/business_models.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/providers/auth_state.dart';
import '../../../../core/network/dio_client.dart';
import '../widgets/voice_search_dialog.dart';
import '../../../../core/network/signalr_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  void _triggerVoiceSearch() {
    showDialog(
      context: context,
      builder: (context) => const VoiceSearchDialog(),
    ).then((voiceQuery) {
      if (voiceQuery != null && voiceQuery is String && voiceQuery.isNotEmpty) {
        _searchController.text = voiceQuery;
        ref.read(searchQueryProvider.notifier).setQuery(voiceQuery, isVoice: true);
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final searchResultsAsync = ref.watch(searchResultsProvider);
    final queryState = ref.watch(searchQueryProvider);
    final favorites = ref.watch(favoritesProvider);
    final authState = ref.watch(authProvider);

    if (authState is AuthAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SignalRService().connect(authState.userId, authState.userType, context);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Explore Local',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          'Vocal for Sanatan',
                          style: TextStyle(
                            color: const Color(0xFFC8A97E),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: const Color(0xFFC8A97E).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.redAccent, size: 24),
                      onPressed: () {
                        ref.read(authProvider.notifier).logout();
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Search Header Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1A1A1A).withValues(alpha: 0.95),
                        const Color(0xFF2C1E14).withValues(alpha: 0.90),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: const Color(0xFFC8A97E).withValues(alpha: 0.25)),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC8A97E).withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Search Bar
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Search restaurants, services, shops...',
                                hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                                prefixIcon: const Icon(Icons.search, color: Color(0xFFC8A97E)),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, color: Colors.white38),
                                        onPressed: () {
                                          _searchController.clear();
                                          ref.read(searchQueryProvider.notifier).setQuery('');
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: Colors.black54,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onChanged: (val) {
                                ref.read(searchQueryProvider.notifier).setQuery(val);
                                setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _triggerVoiceSearch,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC8A97E),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFC8A97E).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ],
                              ),
                              child: const Icon(Icons.mic, color: Colors.black, size: 22),
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E2416),
                          foregroundColor: const Color(0xFFC8A97E),
                          minimumSize: const Size(double.infinity, 44),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: const Color(0xFFC8A97E).withValues(alpha: 0.2)),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => context.push('/for-you'),
                        icon: const Icon(Icons.auto_awesome, size: 16),
                        label: const Text('AI Feed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Categories Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, top: 15, bottom: 10),
                child: Text(
                  'Categories',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Category list (Horizontal Pills)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: categoriesAsync.when(
                  data: (categories) => ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    itemCount: categories.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isSelected = queryState.selectedCategoryId == null;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: ChoiceChip(
                            label: const Text('All'),
                            selected: isSelected,
                            onSelected: (selected) {
                              ref.read(searchQueryProvider.notifier).clearCategory();
                            },
                            backgroundColor: const Color(0xFF1E1E1E),
                            selectedColor: const Color(0xFFC8A97E),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.black : Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }
                      final category = categories[index - 1];
                      final isSelected = queryState.selectedCategoryId == category.categoryId;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: ChoiceChip(
                          label: Text(category.categoryName),
                          selected: isSelected,
                          onSelected: (selected) {
                            ref
                                .read(searchQueryProvider.notifier)
                                .setCategory(selected ? category.categoryId : null);
                          },
                          backgroundColor: const Color(0xFF1E1E1E),
                          selectedColor: const Color(0xFFC8A97E),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                  loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFC8A97E))),
                  error: (err, stack) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Error loading categories', style: TextStyle(color: Colors.redAccent)),
                  ),
                ),
              ),
            ),

            // Business Results Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          queryState.query.isEmpty && queryState.selectedCategoryId == null
                              ? 'All Businesses'
                              : 'Search Results',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (favorites.isNotEmpty)
                          Text(
                            '${favorites.length} Saved',
                            style: const TextStyle(
                              color: Color(0xFFC8A97E),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const Text(
                            'Sort by: ',
                            style: TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          _buildSortChip(ref, 'distance', 'Nearest (PIN Code)', queryState.sortBy),
                          const SizedBox(width: 8),
                          _buildSortChip(ref, 'alphabetical', 'Alphabetical (A-Z)', queryState.sortBy),
                          const SizedBox(width: 8),
                          _buildSortChip(ref, 'reviews', 'Top Rated', queryState.sortBy),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search Results List
            searchResultsAsync.when(
              data: (businesses) {
                if (businesses.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(
                        child: Text(
                          'No businesses found matching your criteria.',
                          style: TextStyle(color: Colors.white38),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final business = businesses[index];
                        final isFav = ref.read(favoritesProvider.notifier).isFavorite(business.businessId);

                        return _buildBusinessCard(context, ref, business, isFav);
                      },
                      childCount: businesses.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(50.0),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFFC8A97E))),
                ),
              ),
              error: (err, stack) => SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text('Error loading businesses: $err', style: const TextStyle(color: Colors.redAccent)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFC8A97E),
        tooltip: 'AI Search Assistant',
        onPressed: () => context.push('/ai-assistant'),
        child: const Icon(Icons.auto_awesome, color: Colors.black),
      ),
    );
  }

  Widget _buildBusinessCard(BuildContext context, WidgetRef ref, BusinessDto business, bool isFav) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image/Accent banner
              Stack(
                children: [
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2E2E2E),
                          const Color(0xFF121212),
                        ],
                      ),
                    ),
                    child: business.photos.isNotEmpty
                        ? Image.network(
                            '${Uri.parse(DioClient().dio.options.baseUrl).origin}${business.photos.first}',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: const Color(0xFF2A2A2A),
                              child: const Icon(Icons.store, color: Color(0xFFC8A97E), size: 40),
                            ),
                          )
                        : Container(
                            color: const Color(0xFF2A2A2A),
                            child: const Icon(Icons.store, color: Color(0xFFC8A97E), size: 40),
                          ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      radius: 18,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.redAccent : Colors.white70,
                          size: 18,
                        ),
                        onPressed: () {
                          ref.read(favoritesProvider.notifier).toggleFavorite(business.businessId);
                        },
                      ),
                    ),
                  ),
                  if (business.categoryName != null)
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          business.categoryName!,
                          style: const TextStyle(color: Color(0xFFC8A97E), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),

              // Title and details
              Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            business.businessName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Color(0xFFC8A97E), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              business.averageRating.toStringAsFixed(1),
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              ' (${business.reviewCount})',
                              style: const TextStyle(color: Colors.white38, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      business.description,
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFFC8A97E), size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            business.address.isNotEmpty && business.city.isNotEmpty
                                ? '${business.address}, ${business.city}'
                                : (business.address.isNotEmpty
                                    ? business.address
                                    : (business.city.isNotEmpty ? business.city : 'No address registered')),
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortChip(WidgetRef ref, String sortVal, String label, String currentSort) {
    final isSelected = currentSort == sortVal;
    return ChoiceChip(
      showCheckmark: false,
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          ref.read(searchQueryProvider.notifier).setSortBy(sortVal);
        }
      },
      backgroundColor: const Color(0xFF1E1E1E),
      selectedColor: const Color(0xFFC8A97E),
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white70,
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? const Color(0xFFC8A97E) : Colors.white.withValues(alpha: 0.1),
        ),
      ),
    );
  }
}
