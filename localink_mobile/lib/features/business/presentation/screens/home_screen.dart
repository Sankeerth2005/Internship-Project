import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getUserLocation();
    });
    SignalRService().addNotificationListener(_onNotificationReceived);
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      ref.read(searchQueryProvider.notifier).setLocation(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  @override
  void dispose() {
    SignalRService().removeNotificationListener(_onNotificationReceived);
    _searchController.dispose();
    super.dispose();
  }

  void _onNotificationReceived(String message) {
    if (message.contains('BusinessUpdated') || 
        message.contains('BusinessDeleted') || 
        message.contains('status') || 
        message.contains('closure')) {
      ref.invalidate(searchResultsProvider);
    }
  }
  void _triggerVoiceSearch() {
    showDialog(
      context: context,
      builder: (context) => const VoiceSearchDialog(),
    ).then((voiceQuery) {
      if (voiceQuery != null && voiceQuery is String && voiceQuery.isNotEmpty) {
        setState(() {
          _searchController.text = voiceQuery;
        });
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
      backgroundColor: const Color(0xFF080706), // Obsidian Black
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Premium Saffron/National Header Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Traditional Mandala/Sun symbol container
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [Color(0xFFFF9F00), Color(0xFFFF5100)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF6B00).withValues(alpha: 0.4),
                                blurRadius: 10,
                                spreadRadius: 1,
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.wb_sunny_rounded, // Surya/Sun representation
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Explore Local ',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                // Subtle Tricolor Flag Pill
                                Container(
                                  width: 14,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFFFF6B00), // Saffron
                                        Colors.white,      // White
                                        Color(0xFF2E7D32), // Green
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.all(Radius.circular(1)),
                                  ),
                                ),
                              ],
                            ),
                            const Text(
                              'Vocal for Sanatan',
                              style: TextStyle(
                                color: Color(0xFFFF6B00), // Pure Saffron
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFF3333).withValues(alpha: 0.1),
                          border: Border.all(color: const Color(0xFFFF3333).withValues(alpha: 0.2)),
                        ),
                        child: const Icon(Icons.logout_rounded, color: Color(0xFFFF3333), size: 18),
                      ),
                      onPressed: () {
                        ref.read(authProvider.notifier).logout();
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Futuristic Glassmorphic Search Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF181614).withValues(alpha: 0.8),
                        const Color(0xFF0C0B0A).withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: const Color(0xFFFF6B00).withValues(alpha: 0.2),
                      width: 1.2,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B00).withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Search Bar & Mic
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F0E0D),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Search restaurants, services, shops...',
                                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFFF6B00), size: 20),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear_rounded, color: Colors.white38, size: 18),
                                          onPressed: () {
                                            _searchController.clear();
                                            ref.read(searchQueryProvider.notifier).setQuery('');
                                          },
                                        )
                                      : null,
                                  filled: false,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onChanged: (val) {
                                  ref.read(searchQueryProvider.notifier).setQuery(val);
                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _triggerVoiceSearch,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF7A00), Color(0xFFFF5100)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF6B00).withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: const Icon(Icons.mic_none_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // AI Assistant quick-feed pill
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B00).withValues(alpha: 0.08),
                          foregroundColor: const Color(0xFFFF7A00),
                          minimumSize: const Size(double.infinity, 45),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: const Color(0xFFFF6B00).withValues(alpha: 0.2), width: 1),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => context.push('/for-you'),
                        icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                        label: const Text(
                          'ASK AI ASSISTANT FEED',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Categories Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 24, top: 20, bottom: 12),
                child: Row(
                  children: [
                    const Icon(Icons.spa_rounded, color: Color(0xFFFF6B00), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Categories',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Horizontal Categories list with traditional icons
            SliverToBoxAdapter(
              child: SizedBox(
                height: 52,
                child: categoriesAsync.when(
                  data: (categories) => ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    itemCount: categories.length + 1,
                    itemBuilder: (context, index) {
                      final isAll = index == 0;
                      final isSelected = isAll 
                          ? queryState.selectedCategoryId == null
                          : queryState.selectedCategoryId == categories[index - 1].categoryId;
                      final label = isAll ? 'All' : categories[index - 1].categoryName;
                      
                      // Assign traditional Indian outline icons to categories
                      IconData catIcon = Icons.brightness_7_outlined; // Default sun
                      if (!isAll) {
                        final name = label.toLowerCase();
                        if (name.contains('restaurant') || name.contains('food') || name.contains('eat')) {
                          catIcon = Icons.villa_outlined; // Temple dome / shelter
                        } else if (name.contains('shop') || name.contains('grocery') || name.contains('store')) {
                          catIcon = Icons.storefront_outlined;
                        } else if (name.contains('service') || name.contains('mechanic') || name.contains('salon')) {
                          catIcon = Icons.construction_outlined;
                        } else if (name.contains('health') || name.contains('doctor') || name.contains('medical')) {
                          catIcon = Icons.local_hospital_outlined;
                        } else {
                          catIcon = Icons.spa_outlined; // Lotus outline
                        }
                      } else {
                        catIcon = Icons.spa_outlined; // All shows Lotus
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: ChoiceChip(
                          showCheckmark: false,
                          avatar: Icon(
                            catIcon,
                            color: isSelected ? Colors.black : const Color(0xFFFF6B00),
                            size: 16,
                          ),
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (isAll) {
                              ref.read(searchQueryProvider.notifier).clearCategory();
                            } else {
                              ref.read(searchQueryProvider.notifier).setCategory(selected ? categories[index - 1].categoryId : null);
                            }
                          },
                          backgroundColor: const Color(0xFF141210),
                          selectedColor: const Color(0xFFFF6B00),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : Colors.white70,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                            side: BorderSide(
                              color: isSelected 
                                  ? const Color(0xFFFF6B00)
                                  : const Color(0xFF25211F),
                              width: 1,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A00))),
                  error: (err, stack) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Error loading categories', style: TextStyle(color: Colors.redAccent)),
                  ),
                ),
              ),
            ),

            // Business Results Header & Sorting Chips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          queryState.query.isEmpty && queryState.selectedCategoryId == null
                              ? 'Verified Listings'
                              : 'Found Matches',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (favorites.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B00).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFF6B00).withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              '${favorites.length} SAVED',
                              style: const TextStyle(
                                color: Color(0xFFFF6B00),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Glassmorphic Sort Chips Bar
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          const Icon(Icons.sort_rounded, color: Colors.white38, size: 14),
                          const SizedBox(width: 8),
                          _buildSortChip(ref, 'distance', 'Nearest first', queryState.sortBy),
                          const SizedBox(width: 8),
                          _buildSortChip(ref, 'alphabetical', 'A-Z order', queryState.sortBy),
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
                      padding: EdgeInsets.all(50.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.search_off_rounded, color: Colors.white24, size: 48),
                            SizedBox(height: 15),
                            Text(
                              'No local businesses found.',
                              style: TextStyle(color: Colors.white38, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ],
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
                  child: Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00))),
                ),
              ),
              error: (err, stack) => SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B00).withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 2,
            )
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: const Color(0xFFFF6B00),
          foregroundColor: Colors.black,
          tooltip: 'AI Search Assistant',
          onPressed: () => context.push('/ai-assistant'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.auto_awesome_rounded, color: Colors.black, size: 24),
        ),
      ),
    );
  }

  Widget _buildBusinessCard(BuildContext context, WidgetRef ref, BusinessDto business, bool isFav) {
    // Determine location distance pill details
    String locationText = business.city;
    if (business.distance != null) {
      locationText = '${business.distance!.toStringAsFixed(1)} km away';
    } else if (business.address.isNotEmpty) {
      locationText = business.address;
    }

    return GestureDetector(
      onTap: () => context.push('/business-detail/${business.businessId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF141210), // Warm charcoal
          border: Border.all(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.12),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image Banner
              Stack(
                children: [
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF221F1C),
                          Color(0xFF0F0E0D),
                        ],
                      ),
                    ),
                    child: business.photos.isNotEmpty
                        ? Image.network(
                            '${Uri.parse(DioClient().dio.options.baseUrl).origin}${business.photos.first}',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: const Color(0xFF1C1917),
                              child: const Icon(Icons.storefront_rounded, color: Color(0xFFFF6B00), size: 45),
                            ),
                          )
                        : Container(
                            color: const Color(0xFF1C1917),
                            child: const Icon(Icons.storefront_rounded, color: Color(0xFFFF6B00), size: 45),
                          ),
                  ),
                  // Gradient Overlay for text visibility
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.6),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.5),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  // Favorite Button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withValues(alpha: 0.6),
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
                  // Distance / Locality Pill
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B00), // Saffron back
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.navigation_rounded, color: Colors.black, size: 10),
                          const SizedBox(width: 4),
                          Text(
                            locationText,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Category Pill
                  if (business.categoryName != null)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFF6B00).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.spa_rounded, color: Color(0xFFFF6B00), size: 10), // Lotus
                            const SizedBox(width: 4),
                            Text(
                              business.categoryName!.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFFFF6B00),
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              // Title and details
              Padding(
                padding: const EdgeInsets.all(16),
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
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              business.averageRating.toStringAsFixed(1),
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              ' (${business.reviewCount})',
                              style: const TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      business.description,
                      style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: Color(0xFFFF6B00), size: 14),
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
      onSelected: (selected) async {
        if (selected) {
          if (sortVal == 'distance') {
            await _getUserLocation();
          }
          ref.read(searchQueryProvider.notifier).setSortBy(sortVal);
        }
      },
      backgroundColor: const Color(0xFF141210),
      selectedColor: const Color(0xFFFF6B00).withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFFFF6B00) : Colors.white70,
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? const Color(0xFFFF6B00) : const Color(0xFF25211F),
          width: isSelected ? 1.2 : 1,
        ),
      ),
    );
  }
}
