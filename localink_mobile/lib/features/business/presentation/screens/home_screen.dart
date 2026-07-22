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

  // Recent searches list
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
    } else if (name.contains('car') || name.contains('auto') || name.contains('vehicle') || name.contains('bike')) {
      return Icons.directions_car_rounded;
    } else if (name.contains('education') || name.contains('school') || name.contains('college') || name.contains('coaching') || name.contains('tutor')) {
      return Icons.school_rounded;
    } else if (name.contains('entertainment') || name.contains('movie') || name.contains('cinema') || name.contains('game') || name.contains('event') || name.contains('fun')) {
      return Icons.movie_rounded;
    } else if (name.contains('finance') || name.contains('bank') || name.contains('money') || name.contains('insurance') || name.contains('loan') || name.contains('tax')) {
      return Icons.account_balance_rounded;
    } else if (name.contains('legal') || name.contains('law') || name.contains('advocate') || name.contains('court') || name.contains('lawyer')) {
      return Icons.gavel_rounded;
    } else if (name.contains('marketing') || name.contains('advertis') || name.contains('media') || name.contains('agency') || name.contains('pr')) {
      return Icons.campaign_rounded;
    } else if (name.contains('pet') || name.contains('vet') || name.contains('dog') || name.contains('animal')) {
      return Icons.pets_rounded;
    } else if (name.contains('security') || name.contains('guard') || name.contains('cctv') || name.contains('shield') || name.contains('safety')) {
      return Icons.shield_rounded;
    } else if (name.contains('travel') || name.contains('tour') || name.contains('flight') || name.contains('trip') || name.contains('agent') || name.contains('ticket')) {
      return Icons.flight_takeoff_rounded;
    } else if (name.contains('temple') || name.contains('religious') || name.contains('pooja') || name.contains('sanatan')) {
      return Icons.spa_rounded;
    } else if (name.contains('beauty') || name.contains('salon') || name.contains('spa') || name.contains('parlor') || name.contains('wellness')) {
      return Icons.content_cut_rounded;
    } else if (name.contains('real estate') || name.contains('property') || name.contains('house') || name.contains('rent')) {
      return Icons.home_work_rounded;
    } else if (name.contains('hotel') || name.contains('resort') || name.contains('stay') || name.contains('lodge')) {
      return Icons.hotel_rounded;
    } else if (name.contains('fashion') || name.contains('cloth') || name.contains('handloom') || name.contains('textile')) {
      return Icons.checkroom_rounded;
    } else if (name.contains('electronic') || name.contains('mobile') || name.contains('laptop') || name.contains('tech')) {
      return Icons.devices_rounded;
    } else if (name.contains('misc') || name.contains('other')) {
      return Icons.category_rounded;
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
    } else if (name.contains('spa') || name.contains('massage')) {
      return Icons.spa_rounded;
    } else if (name.contains('gym') || name.contains('fitness')) {
      return Icons.fitness_center_rounded;
    } else if (name.contains('hotel') || name.contains('room')) {
      return Icons.hotel_rounded;
    } else if (name.contains('car') || name.contains('washing') || name.contains('mechanic')) {
      return Icons.car_repair_rounded;
    } else if (name.contains('school') || name.contains('class') || name.contains('coaching')) {
      return Icons.menu_book_rounded;
    } else if (name.contains('law') || name.contains('legal')) {
      return Icons.gavel_rounded;
    } else if (name.contains('bank') || name.contains('audit') || name.contains('tax')) {
      return Icons.monetization_on_rounded;
    } else if (name.contains('camera') || name.contains('photo') || name.contains('studio')) {
      return Icons.camera_alt_rounded;
    } else if (name.contains('pet') || name.contains('food')) {
      return Icons.pets_rounded;
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

    // Determine real user name
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
        backgroundColor: const Color(0xFF080706),
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ─── 1. HEADER BAR (Real User Greeting + AI Feed Button) ───
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
                              child: const Center(
                                child: Icon(Icons.person_rounded, color: Colors.white, size: 24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello 👋',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
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
                          // AI Feed Button
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF7A00).withValues(alpha: 0.15),
                              foregroundColor: const Color(0xFFFF7A00),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: const BorderSide(color: Color(0xFFFF7A00), width: 1),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: () => context.push('/for-you'),
                            icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                            label: const Text(
                              'AI Feed',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
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
                                color: const Color(0xFF141210),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
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
                          // Voice Search Microphone Button
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

              // ─── 3. HERO BANNER (Clean Consumer Version - No Store Registration Button) ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF7A00), Color(0xFFFF5100)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF7A00).withValues(alpha: 0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Explore Your Local Business',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Discover top-rated services, stores & verified deals near you.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.explore_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── 4. MAIN CATEGORIES SECTION ───
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                      height: 95,
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
                            final catIcon = isAll ? Icons.apps_rounded : _getCategoryIcon(label);

                            return GestureDetector(
                              onTap: () {
                                if (isAll) {
                                  ref.read(searchQueryProvider.notifier).clearCategory();
                                } else {
                                  ref.read(searchQueryProvider.notifier).setCategory(categories[index - 1].categoryId);
                                }
                              },
                              child: AnimatedScale(
                                scale: isSelected ? 1.08 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutCubic,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 52,
                                        height: 52,
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
                                                    color: const Color(0xFFFF7A00).withValues(alpha: 0.35),
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
                                      const SizedBox(height: 6),
                                      Text(
                                        label,
                                        style: TextStyle(
                                          color: isSelected ? const Color(0xFFFF7A00) : Colors.white60,
                                          fontSize: 11,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
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

              // ─── 5. SUB-CATEGORIES HORIZONTAL CHIPS BAR (WHEN CATEGORY IS SELECTED) ───
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
                                      color: Color(0xFFFF7A00),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.2,
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
                                              fontSize: 11.5,
                                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                              color: isSelected ? Colors.black : Colors.white70,
                                            ),
                                          ),
                                          backgroundColor: const Color(0xFF141210),
                                          selectedColor: const Color(0xFFFF7A00),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                            side: BorderSide(
                                              color: isSelected ? const Color(0xFFFF7A00) : Colors.white.withValues(alpha: 0.1),
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

              // ─── 6. SORT BUTTON WITH UP/DOWN ARROW ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Verified Businesses',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
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

              // ─── 7. BUSINESS LISTINGS & AUTOCOMPLETE OVERLAY ───
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

              // Bottom Padding so content scrolls nicely above floating glassmorphic nav bar
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
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
        margin: const EdgeInsets.only(bottom: 18),
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
                  // Distance Badge
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
                  // Favorite Heart Button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () {
                        ref.read(favoritesProvider.notifier).toggleFavorite(business.businessId);
                      },
                      child: AnimatedScale(
                        scale: isFav ? 1.25 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.elasticOut,
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
                  ),
                ],
              ),

              // Business Details Body
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
