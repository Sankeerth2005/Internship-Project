import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/business_provider.dart';
import '../../data/models/business_models.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/providers/auth_state.dart';
import '../../../auth/providers/user_provider.dart';
import '../../../../core/network/dio_client.dart';
import '../widgets/voice_search_dialog.dart';
import '../../../../core/network/signalr_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final List<String> _recentSearches = ['Restaurant', 'Car Service', 'Doctor', 'Salon'];
  bool _showAutocomplete = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getUserLocation();
    });
    SignalRService().addNotificationListener(_onNotificationReceived);

    _searchFocusNode.addListener(() {
      setState(() {});
    });
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
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      ref.read(searchQueryProvider.notifier).setLocation(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
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

  void _openSortBottomSheet(String currentSort) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141210),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sort Businesses',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white60),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10),
                _buildSortOption('distance', 'Nearest (Distance)', Icons.near_me_rounded, currentSort),
                _buildSortOption('alphabetical', 'A-Z Order', Icons.sort_by_alpha_rounded, currentSort),
                _buildSortOption('alphabetical_desc', 'Z-A Order', Icons.sort_by_alpha_rounded, currentSort),
                _buildSortOption('reviews', 'Top Rated', Icons.star_rounded, currentSort),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String sortKey, String label, IconData icon, String currentSort) {
    final isSelected = currentSort == sortKey;
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFFFF7A00) : Colors.white60),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? const Color(0xFFFF7A00) : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFFFF7A00)) : null,
      onTap: () {
        ref.read(searchQueryProvider.notifier).setSortBy(sortKey);
        Navigator.pop(context);
      },
    );
  }

  void _openFullCategoriesModal(List<CategoryDto> categories) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141210),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'All Categories',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white60),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10, height: 1),
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.88,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final icon = _getCategoryIcon(cat.categoryName);

                      return GestureDetector(
                        onTap: () {
                          ref.read(searchQueryProvider.notifier).setCategory(cat.categoryId);
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1917),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFFFF7A00).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFFF7A00).withValues(alpha: 0.12),
                                ),
                                child: Icon(icon, color: const Color(0xFFFF7A00), size: 22),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Text(
                                  cat.categoryName,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('restaurant') || name.contains('food') || name.contains('cafe') || name.contains('bakery') || name.contains('eat') || name.contains('dining')) {
      return Icons.restaurant_rounded;
    } else if (name.contains('shop') || name.contains('grocery') || name.contains('store') || name.contains('supermarket') || name.contains('retail')) {
      return Icons.shopping_bag_rounded;
    } else if (name.contains('service') || name.contains('repair') || name.contains('mechanic') || name.contains('plumber')) {
      return Icons.build_rounded;
    } else if (name.contains('health') || name.contains('doctor') || name.contains('medical') || name.contains('hospital') || name.contains('pharmacy')) {
      return Icons.local_hospital_rounded;
    } else if (name.contains('car') || name.contains('auto') || name.contains('vehicle') || name.contains('bike') || name.contains('automotive')) {
      return Icons.directions_car_rounded;
    } else if (name.contains('education') || name.contains('school') || name.contains('college') || name.contains('coaching') || name.contains('tutor')) {
      return Icons.school_rounded;
    } else if (name.contains('entertainment') || name.contains('movie') || name.contains('cinema') || name.contains('game') || name.contains('event') || name.contains('fun')) {
      return Icons.movie_rounded;
    } else if (name.contains('finance') || name.contains('bank') || name.contains('money') || name.contains('insurance') || name.contains('loan') || name.contains('tax')) {
      return Icons.account_balance_rounded;
    } else if (name.contains('legal') || name.contains('law') || name.contains('advocate') || name.contains('court') || name.contains('lawyer')) {
      return Icons.gavel_rounded;
    } else if (name.contains('beauty') || name.contains('salon') || name.contains('spa') || name.contains('parlor') || name.contains('wellness')) {
      return Icons.content_cut_rounded;
    } else if (name.contains('fitness') || name.contains('gym')) {
      return Icons.fitness_center_rounded;
    } else {
      return Icons.grid_view_rounded;
    }
  }

  IconData _getSubcategoryIcon(String subcategoryName) {
    final name = subcategoryName.toLowerCase();
    if (name.contains('fast food') || name.contains('pizza') || name.contains('burger')) {
      return Icons.fastfood_rounded;
    } else if (name.contains('cafe') || name.contains('coffee') || name.contains('tea')) {
      return Icons.local_cafe_rounded;
    } else if (name.contains('clinic') || name.contains('dentist') || name.contains('eye')) {
      return Icons.medical_services_rounded;
    } else if (name.contains('gym') || name.contains('fitness')) {
      return Icons.fitness_center_rounded;
    } else {
      return Icons.label_important_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final searchResultsAsync = ref.watch(searchResultsProvider);
    final queryState = ref.watch(searchQueryProvider);
    final favorites = ref.watch(favoritesProvider);
    final authState = ref.watch(authProvider);
    final userProfileAsync = ref.watch(userProfileProvider);

    if (authState is AuthAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SignalRService().connect(authState.userId, authState.userType, context);
      });
    }

    // Determine real user name dynamically
    String userName = 'User';
    userProfileAsync.whenData((profile) {
      if (profile.fullName.isNotEmpty) {
        userName = profile.fullName;
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
        } else if (queryState.query.isNotEmpty || queryState.selectedCategoryId != null) {
          ref.read(searchQueryProvider.notifier).setQuery('');
          ref.read(searchQueryProvider.notifier).clearCategory();
          _searchController.clear();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF070605),
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ─── 1. HEADER BAR (Real User Greeting + AI Feed Button — NO Notifications Icon) ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
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
                                    color: const Color(0xFFFF7A00).withValues(alpha: 0.3),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                  style: const TextStyle(
                                    fontFamily: 'serif',
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
                                      fontFamily: 'Inter',
                                      color: Colors.white.withValues(alpha: 0.6),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // AI Feed Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7A00).withValues(alpha: 0.15),
                          foregroundColor: const Color(0xFFFF7A00),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: Color(0xFFFF7A00), width: 1.2),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        onPressed: () => context.push('/for-you'),
                        icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                        label: const Text(
                          'AI Feed',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── 2. SEARCH BAR WITH INTEGRATED VOICE SEARCH ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFF14110E),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF2E241A),
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search business, category, area...',
                                  hintStyle: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: Color(0xFF70655B),
                                    fontSize: 13.5,
                                  ),
                                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFFF7A00), size: 20),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear_rounded, color: Colors.white38, size: 18),
                                          onPressed: () {
                                            _searchController.clear();
                                            ref.read(searchQueryProvider.notifier).setQuery('');
                                            setState(() {
                                              _showAutocomplete = false;
                                            });
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
                                  setState(() {
                                    _showAutocomplete = val.length >= 3;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Voice Search Button
                          GestureDetector(
                            onTap: _triggerVoiceSearch,
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF8000), Color(0xFFD63E00)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF7A00).withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.mic_rounded, color: Colors.white, size: 24),
                            ),
                          ),
                        ],
                      ),

                      // Recent Searches Chips
                      if (_searchFocusNode.hasFocus && _searchController.text.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                const Icon(Icons.history_rounded, color: Colors.white38, size: 14),
                                const SizedBox(width: 8),
                                ..._recentSearches.map(
                                  (term) => Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ActionChip(
                                      backgroundColor: const Color(0xFF1A1816),
                                      label: Text(term, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                      onPressed: () {
                                        _searchController.text = term;
                                        ref.read(searchQueryProvider.notifier).setQuery(term);
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ─── 3. HERO BANNER CAROUSEL ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Container(
                    width: double.infinity,
                    height: 165,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F0C0A),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFFFF7A00).withValues(alpha: 0.25),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF7A00).withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        children: [
                          // Vector Sunset Temple Canvas Background
                          Positioned.fill(
                            child: CustomPaint(
                              painter: BannerTemplePainter(),
                            ),
                          ),

                          // Banner Content Text & Button
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                RichText(
                                  text: const TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Explore Your\n',
                                        style: TextStyle(
                                          fontFamily: 'serif',
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          height: 1.1,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'Local ',
                                        style: TextStyle(
                                          fontFamily: 'serif',
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFFF8C00),
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'World',
                                        style: TextStyle(
                                          fontFamily: 'serif',
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const SizedBox(
                                  width: 220,
                                  child: Text(
                                    'Discover top-rated services, stores & verified deals near you.',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      color: Color(0xFFCDC3B8),
                                      fontSize: 11.5,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // "Explore Now ->" Saffron Button
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFF8000), Color(0xFFD63E00)],
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Explore Now',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Carousel Dots Indicator
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 16,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF7A00),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.white30,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.white30,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ─── 4. MAIN CATEGORIES SECTION ───
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Categories',
                            style: TextStyle(
                              fontFamily: 'serif',
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          categoriesAsync.when(
                            data: (categories) => GestureDetector(
                              onTap: () => _openFullCategoriesModal(categories),
                              child: const Row(
                                children: [
                                  Text(
                                    'View all',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      color: Color(0xFFFF8C00),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 2),
                                  Icon(Icons.arrow_forward_rounded, color: Color(0xFFFF8C00), size: 14),
                                ],
                              ),
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (e, s) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 95,
                      child: categoriesAsync.when(
                        data: (categories) {
                          // Display 5 primary categories + 1 "More" item
                          final displayCategories = categories.take(5).toList();

                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            itemCount: displayCategories.length + 2, // 0 = All, 1-5 = Cat, 6 = More
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                // "All" Category
                                final isSelected = queryState.selectedCategoryId == null;
                                return _buildCategoryCircleItem(
                                  label: 'All',
                                  icon: Icons.grid_view_rounded,
                                  isSelected: isSelected,
                                  onTap: () => ref.read(searchQueryProvider.notifier).clearCategory(),
                                );
                              } else if (index == displayCategories.length + 1) {
                                // "More" Item
                                return _buildCategoryCircleItem(
                                  label: 'More',
                                  icon: Icons.more_horiz_rounded,
                                  isSelected: false,
                                  onTap: () => _openFullCategoriesModal(categories),
                                );
                              } else {
                                final cat = displayCategories[index - 1];
                                final isSelected = queryState.selectedCategoryId == cat.categoryId;
                                final icon = _getCategoryIcon(cat.categoryName);
                                return _buildCategoryCircleItem(
                                  label: cat.categoryName,
                                  icon: icon,
                                  isSelected: isSelected,
                                  onTap: () => ref.read(searchQueryProvider.notifier).setCategory(cat.categoryId),
                                );
                              }
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A00))),
                        error: (err, stack) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),

              // ─── 5. SUB-CATEGORIES HORIZONTAL CHIPS BAR ───
              if (queryState.selectedCategoryId != null)
                SliverToBoxAdapter(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final subcategoriesAsync = ref.watch(subcategoriesProvider(queryState.selectedCategoryId!));
                      return subcategoriesAsync.when(
                        data: (subcategories) {
                          if (subcategories.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6, bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                  child: Text(
                                    'Sub-Categories',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      color: Color(0xFFFF7A00),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 38,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    itemCount: subcategories.length + 1,
                                    itemBuilder: (context, index) {
                                      final isAll = index == 0;
                                      final isSelected = isAll
                                          ? queryState.selectedSubcategoryId == null
                                          : queryState.selectedSubcategoryId == subcategories[index - 1].subcategoryId;
                                      final label = isAll ? 'All Sub-categories' : subcategories[index - 1].subcategoryName;
                                      final subIcon = isAll ? Icons.tune_rounded : _getSubcategoryIcon(label);

                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: FilterChip(
                                          selected: isSelected,
                                          showCheckmark: false,
                                          avatar: Icon(
                                            subIcon,
                                            size: 14,
                                            color: isSelected ? Colors.black : const Color(0xFFFF7A00),
                                          ),
                                          label: Text(
                                            label,
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 11.5,
                                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                              color: isSelected ? Colors.black : Colors.white70,
                                            ),
                                          ),
                                          backgroundColor: const Color(0xFF14110E),
                                          selectedColor: const Color(0xFFFF7A00),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                            side: BorderSide(
                                              color: isSelected ? const Color(0xFFFF7A00) : const Color(0xFF2E241A),
                                            ),
                                          ),
                                          onSelected: (_) {
                                            if (isAll) {
                                              ref.read(searchQueryProvider.notifier).clearSubcategory();
                                            } else {
                                              ref.read(searchQueryProvider.notifier).setSubcategory(subcategories[index - 1].subcategoryId);
                                            }
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (err, stack) => const SizedBox.shrink(),
                      );
                    },
                  ),
                ),

              // ─── 6. SORT BUTTON HEADER ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Verified Businesses',
                        style: TextStyle(
                          fontFamily: 'serif',
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      // Sort Button
                      GestureDetector(
                        onTap: () => _openSortBottomSheet(queryState.sortBy),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF7A00).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFF7A00)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.swap_vert_rounded, color: Color(0xFFFF7A00), size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Sort ⇅',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: Color(0xFFFF7A00),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── 7. VERIFIED BUSINESS CARDS (Real Data & Real Photos — NO Discount Chips) ───
              searchResultsAsync.when(
                data: (businesses) {
                  final matchingAutocomplete = _showAutocomplete
                      ? businesses.where((b) => b.businessName.toLowerCase().contains(_searchController.text.toLowerCase())).toList()
                      : <BusinessDto>[];

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

                  return SliverMainAxisGroup(
                    slivers: [
                      // Autocomplete Suggestion Overlay Header
                      if (_showAutocomplete && matchingAutocomplete.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF181614),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFFF7A00).withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(
                                    'Quick Suggestions:',
                                    style: TextStyle(color: Color(0xFFFF7A00), fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                ...matchingAutocomplete.take(4).map(
                                  (b) => ListTile(
                                    leading: const Icon(Icons.search_rounded, color: Colors.white38, size: 16),
                                    title: Text(b.businessName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                    subtitle: Text(b.categoryName ?? b.city, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                    onTap: () {
                                      _searchController.text = b.businessName;
                                      ref.read(searchQueryProvider.notifier).setQuery(b.businessName);
                                      setState(() {
                                        _showAutocomplete = false;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Main Business Card Feed
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final business = businesses[index];
                              final isFav = favorites.contains(business.businessId);

                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: Duration(milliseconds: 250 + (index * 50).clamp(0, 300)),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Transform.translate(
                                    offset: Offset(0, 24 * (1 - value)),
                                    child: Opacity(opacity: value, child: child),
                                  );
                                },
                                child: _buildBusinessCard(context, ref, business, isFav),
                              );
                            },
                            childCount: businesses.length,
                          ),
                        ),
                      ),
                    ],
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

              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCircleItem({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFFFF8000), Color(0xFFD63E00)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : null,
                color: isSelected ? null : const Color(0xFF14110E),
                border: Border.all(
                  color: isSelected ? const Color(0xFFFF7A00) : const Color(0xFF2E241A),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF7A00).withValues(alpha: 0.35),
                          blurRadius: 12,
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFFFF7A00),
                size: 24,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                color: isSelected ? const Color(0xFFFF7A00) : Colors.white70,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessCard(BuildContext context, WidgetRef ref, BusinessDto business, bool isFav) {
    String distanceText = 'Near you';
    if (business.distance != null) {
      distanceText = '${business.distance!.toStringAsFixed(1)} km away';
    }

    String cityText = business.city;
    if (cityText.isEmpty && business.address.isNotEmpty) {
      cityText = business.address;
    }

    final categorySubtitle = business.categoryName ?? 'Local Business';

    return GestureDetector(
      onTap: () => context.push('/business-detail/${business.businessId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0C0A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFF7A00).withValues(alpha: 0.2),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Side Photo with Rating Badge Overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 110,
                    height: 110,
                    color: const Color(0xFF1A140E),
                    child: business.photos.isNotEmpty
                        ? Image.network(
                            '${Uri.parse(DioClient().dio.options.baseUrl).origin}${business.photos.first}',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.storefront_rounded,
                              color: Color(0xFFFF7A00),
                              size: 40,
                            ),
                          )
                        : const Icon(
                            Icons.storefront_rounded,
                            color: Color(0xFFFF7A00),
                            size: 40,
                          ),
                  ),
                ),
                // Rating Overlay Badge on Image (Bottom-Left)
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A1E),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFF4CAF50), size: 12),
                        const SizedBox(width: 3),
                        Text(
                          business.averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Right Side Business Info Column (NO DISCOUNT TAGS)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                business.businessName,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF4CAF50),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                      // Favorite Heart Button
                      GestureDetector(
                        onTap: () {
                          ref.read(favoritesProvider.notifier).toggleFavorite(business.businessId);
                        },
                        child: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? const Color(0xFFFF3333) : Colors.white54,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Category Subtitle
                  Text(
                    categorySubtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFFA59B90),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Location Address
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFFFF7A00),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          cityText.isNotEmpty ? cityText : 'Local City',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Distance Tag
                  Row(
                    children: [
                      const Icon(
                        Icons.near_me_rounded,
                        color: Color(0xFFFF8C00),
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        distanceText,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFFFF8C00),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
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
    );
  }
}

class BannerTemplePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Glowing Sunset Aura Background
    final sunPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.7, -0.3),
        radius: 0.9,
        colors: [
          const Color(0xFFFF6A00).withValues(alpha: 0.45),
          const Color(0xFF381200).withValues(alpha: 0.2),
          Colors.transparent,
        ],
      ).createShader(rect);

    canvas.drawRect(rect, sunPaint);

    // Flowing Golden Light Lines
    final wavePaint = Paint()
      ..color = const Color(0xFFFF8C00).withValues(alpha: 0.3)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final path1 = Path()
      ..moveTo(size.width * 0.4, size.height)
      ..cubicTo(size.width * 0.6, size.height * 0.4, size.width * 0.8, size.height * 0.8, size.width, size.height * 0.3);

    canvas.drawPath(path1, wavePaint);

    // Silhouetted Temple Spires on Right
    final templePaint = Paint()
      ..color = const Color(0xFF160D07)
      ..style = PaintingStyle.fill;

    final templePath = Path();
    templePath.moveTo(size.width * 0.6, size.height);
    templePath.lineTo(size.width * 0.68, size.height * 0.55);
    templePath.lineTo(size.width * 0.74, size.height * 0.45);
    templePath.lineTo(size.width * 0.82, size.height * 0.15); // Main Spire
    templePath.lineTo(size.width * 0.9, size.height * 0.45);
    templePath.lineTo(size.width * 0.96, size.height * 0.55);
    templePath.lineTo(size.width, size.height);
    templePath.close();

    canvas.drawPath(templePath, templePaint);

    // Om Flag at Spire Tip
    final flagPaint = Paint()
      ..color = const Color(0xFFFF7A00)
      ..style = PaintingStyle.fill;

    final flagPath = Path();
    flagPath.moveTo(size.width * 0.82, size.height * 0.15);
    flagPath.lineTo(size.width * 0.87, size.height * 0.18);
    flagPath.lineTo(size.width * 0.82, size.height * 0.22);
    flagPath.close();

    canvas.drawPath(flagPath, flagPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
