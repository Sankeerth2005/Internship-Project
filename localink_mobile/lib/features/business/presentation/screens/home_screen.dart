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
    final authState = ref.watch(authProvider);

    if (authState is AuthAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SignalRService().connect(authState.userId, authState.userType, context);
      });
    }

    // Extract user full name & avatar initials for greeting
    String userName = 'Guest';
    if (authState is AuthAuthenticated) {
      userName = authState.userType.toUpperCase() == 'ADMIN'
          ? 'Admin'
          : authState.userType.toLowerCase() == 'client' || authState.userType.toLowerCase() == 'businessowner'
              ? 'Owner'
              : 'User';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF080706), // Obsidian Black
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ─── 1. HEADER BAR (Avatar + Greeting + Notification Bell) ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // User Avatar Circle
                        GestureDetector(
                          onTap: () => context.push('/profile'),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF9F00), Color(0xFFFF5500)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF7A00).withValues(alpha: 0.25),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.person_rounded, color: Colors.white, size: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Hello 👋',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Notification Bell with Badge
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF161412),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                              ),
                              child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
                            ),
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF3333),
                                  shape: BoxShape.circle,
                                ),
                                child: const Text(
                                  '2',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(10),
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
                  ],
                ),
              ),
            ),

            // ─── 2. SEARCH BAR WITH INTEGRATED FILTER BUTTON ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF141210),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search business, category, area...',
                            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
                            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFFF7A00), size: 20),
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
                    // Saffron Filter Action Button
                    GestureDetector(
                      onTap: _triggerVoiceSearch,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF7A00), Color(0xFFFF5100)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF7A00).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── 3. HERO PROMOTIONAL BANNER CARD ("Post your Business for Free") ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF7A00), Color(0xFFFF5100)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF7A00).withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Post your Business for ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'Free',
                                  style: TextStyle(
                                    color: Colors.amber.shade200,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Connect with local customers & get genuine verified leads.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 11.5,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: () => context.push('/register-business'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFFFF6B00),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: const Text(
                                'Post your business',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── 4. CIRCULAR CATEGORY CHIPS ───
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      'Categories',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 100,
                    child: categoriesAsync.when(
                      data: (categories) => ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        itemCount: categories.length + 1,
                        itemBuilder: (context, index) {
                          final isAll = index == 0;
                          final isSelected = isAll 
                              ? queryState.selectedCategoryId == null
                              : queryState.selectedCategoryId == categories[index - 1].categoryId;
                          final label = isAll ? 'All' : categories[index - 1].categoryName;
                          
                          IconData catIcon = Icons.category_rounded;
                          if (!isAll) {
                            final name = label.toLowerCase();
                            if (name.contains('restaurant') || name.contains('food') || name.contains('eat')) {
                              catIcon = Icons.restaurant_rounded;
                            } else if (name.contains('shop') || name.contains('grocery') || name.contains('store')) {
                              catIcon = Icons.shopping_bag_rounded;
                            } else if (name.contains('service') || name.contains('mechanic') || name.contains('salon')) {
                              catIcon = Icons.build_rounded;
                            } else if (name.contains('health') || name.contains('doctor') || name.contains('medical')) {
                              catIcon = Icons.local_hospital_rounded;
                            } else {
                              catIcon = Icons.grid_view_rounded;
                            }
                          } else {
                            catIcon = Icons.apps_rounded;
                          }

                          return GestureDetector(
                            onTap: () {
                              if (isAll) {
                                ref.read(searchQueryProvider.notifier).clearCategory();
                              } else {
                                ref.read(searchQueryProvider.notifier).setCategory(categories[index - 1].categoryId);
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? const Color(0xFFFF7A00) : const Color(0xFF141210),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFFFF7A00) : Colors.white.withValues(alpha: 0.08),
                                        width: 1.5,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFFFF7A00).withValues(alpha: 0.3),
                                                blurRadius: 10,
                                              )
                                            ]
                                          : [],
                                    ),
                                    child: Icon(
                                      catIcon,
                                      color: isSelected ? Colors.white : Colors.white60,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      color: isSelected ? const Color(0xFFFF7A00) : Colors.white60,
                                      fontSize: 11.5,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A00))),
                      error: (err, stack) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),

            // ─── 5. SEGMENTED FILTER BAR (Featured / Near Me / Sort) ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Featured Listings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Row(
                      children: [
                        _buildSortChip(ref, 'distance', 'Nearest', queryState.sortBy),
                        const SizedBox(width: 6),
                        _buildSortChip(ref, 'reviews', 'Top Rated', queryState.sortBy),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ─── 6. BUSINESS LISTING CARDS ───
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B00).withValues(alpha: 0.35),
                blurRadius: 16,
                spreadRadius: 2,
              )
            ],
          ),
          child: FloatingActionButton(
            backgroundColor: const Color(0xFFFF6B00),
            foregroundColor: Colors.white,
            tooltip: 'Ask AI Assistant',
            onPressed: () => context.push('/ai-assistant'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildSortChip(WidgetRef ref, String sortKey, String label, String currentSort) {
    final isSelected = currentSort == sortKey;
    return GestureDetector(
      onTap: () {
        ref.read(searchQueryProvider.notifier).setSortBy(sortKey);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF7A00).withValues(alpha: 0.15) : const Color(0xFF141210),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF7A00) : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFFF7A00) : Colors.white60,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessCard(BuildContext context, WidgetRef ref, BusinessDto business, bool isFav) {
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
          color: const Color(0xFF141210),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
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
                      color: Color(0xFF1C1917),
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
                  // Gradient Overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.5),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  // Distance Badge (Top Left)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.near_me_rounded, color: Color(0xFFFF7A00), size: 12),
                          const SizedBox(width: 4),
                          Text(
                            locationText,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Favorite Heart Button (Top Right)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () {
                        ref.read(favoritesProvider.notifier).toggleFavorite(business.businessId);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? const Color(0xFFFF3333) : Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Business Info Body
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
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Verified badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified_rounded, color: Color(0xFF4CAF50), size: 12),
                              SizedBox(width: 4),
                              Text('Verified', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      business.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              business.averageRating.toStringAsFixed(1),
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${business.reviewCount} reviews)',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.call_rounded, color: Color(0xFFFF7A00), size: 13),
                            const SizedBox(width: 4),
                            Text(
                              business.phoneNumber.isNotEmpty ? business.phoneNumber : 'Contact',
                              style: const TextStyle(color: Color(0xFFFF7A00), fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
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
}
