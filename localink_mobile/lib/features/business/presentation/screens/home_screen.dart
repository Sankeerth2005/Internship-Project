import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/business_provider.dart';
import '../../providers/category_usage_tracker.dart';
import '../../data/models/business_models.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/providers/auth_state.dart';
import '../../../auth/providers/user_provider.dart';
import '../../../../core/widgets/optimized_network_image.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/network/app_error_formatter.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../../../core/storage/recent_search_store.dart';
import '../../../../core/storage/last_search_store.dart';
import '../../../shared/presentation/widgets/app_state_widget.dart';
import '../widgets/voice_search_dialog.dart';
import '../../../../core/network/signalr_service.dart';
import '../../../home/widgets/home_header.dart';
import '../../../home/widgets/home_search_bar.dart';
import '../../../home/widgets/home_hero_banner.dart';
import '../../../home/widgets/home_category_chips.dart';

// ─── DESIGN TOKENS (aligned to DESIGN_SYSTEM.md) ─────────────────────────────
class _HomeTok {
  static const Color primary = Color(0xFFFF6600);
  static const Color white = Color(0xFFFFFFFF);
  static const Color charcoal = Color(0xFF1A1918);
  static const Color medText = Color(0xFF5F5C58);
  static const Color mutedText = Color(0xFF9F9B96);
  static const Color surface = Color(0xFFF9F8F6);
  static const Color border = Color(0xFFEAE8E3);
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;

  // Recent searches — loaded from device, populated only by real queries
  List<String> _recentSearches = [];
  bool _showAutocomplete = false;

  void _onSearchChangedDebounced(String val) {
    setState(() {
      _showAutocomplete = val.length >= 3;
    });
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      ref.read(searchQueryProvider.notifier).setQuery(val);
      if (val.trim().length >= 2) {
        await LastSearchStore.save(val);
        final updated = await RecentSearchStore.add(val);
        if (mounted) setState(() => _recentSearches = updated);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _getUserLocation();
      final recent = await RecentSearchStore.load();
      final last = await LastSearchStore.load();
      if (last != null && mounted && _searchController.text.isEmpty) {
        _searchController.text = last;
        ref.read(searchQueryProvider.notifier).setQuery(last);
      }
      if (mounted) setState(() => _recentSearches = recent);
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
    _searchDebounce?.cancel();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    SignalRService().removeNotificationListener(_onNotificationReceived);
    _searchController.dispose();
    super.dispose();
  }

  void _onNotificationReceived(String message) {
    if (message.contains('BusinessUpdated') || 
        message.contains('BusinessDeleted') || 
        message.contains('status') || 
        message.contains('closure')) {
      ref.invalidate(searchFeedProvider);
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

  static const List<({String key, String label, String hint, IconData icon})> _sortOptions = [
    (key: 'nearest', label: 'Nearest', hint: 'Closest to you first', icon: Icons.near_me_rounded),
    (key: 'alphabetical', label: 'A–Z', hint: 'Name ascending', icon: Icons.sort_by_alpha_rounded),
    (key: 'alphabetical_desc', label: 'Z–A', hint: 'Name descending', icon: Icons.sort_by_alpha_rounded),
    (key: 'top_rated', label: 'Top rated', hint: 'Highest average rating', icon: Icons.star_rounded),
    (key: 'most_reviewed', label: 'Most reviewed', hint: 'Most customer reviews', icon: Icons.reviews_rounded),
    (key: 'newest', label: 'Newest', hint: 'Recently added first', icon: Icons.fiber_new_rounded),
    (key: 'most_popular', label: 'Most popular', hint: 'Views, favorites & clicks', icon: Icons.trending_up_rounded),
  ];

  String _normalizeSortKey(String sortKey) {
    switch (sortKey) {
      case 'distance':
      case 'nearby':
        return 'nearest';
      case 'reviews':
      case 'rating':
        return 'top_rated';
      case 'popularity':
      case 'popular':
        return 'most_popular';
      default:
        return sortKey;
    }
  }

  String _sortLabelFor(String sortKey) {
    final key = _normalizeSortKey(sortKey);
    for (final option in _sortOptions) {
      if (option.key == key) return option.label;
    }
    return 'Sort';
  }

  void _openSortBottomSheet(String currentSort) {
    final selectedKey = _normalizeSortKey(currentSort);
    showModalBottomSheet(
      context: context,
      backgroundColor: _HomeTok.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _HomeTok.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sort by',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: _HomeTok.charcoal,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Nearest matching businesses appear first',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: _HomeTok.mutedText,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close_rounded, color: _HomeTok.medText),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.55,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _sortOptions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final option = _sortOptions[index];
                      return _buildSortOption(
                        option.key,
                        option.label,
                        option.hint,
                        option.icon,
                        selectedKey,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption(
    String sortKey,
    String label,
    String hint,
    IconData icon,
    String currentSort,
  ) {
    final isSelected = currentSort == sortKey;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ref.read(searchQueryProvider.notifier).setSortBy(sortKey);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? _HomeTok.primary.withValues(alpha: 0.08) : _HomeTok.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? _HomeTok.primary : _HomeTok.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? _HomeTok.primary.withValues(alpha: 0.14)
                      : _HomeTok.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected ? _HomeTok.primary : _HomeTok.medText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: isSelected ? _HomeTok.primary : _HomeTok.charcoal,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hint,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: _HomeTok.mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 22,
                color: isSelected ? _HomeTok.primary : _HomeTok.border,
              ),
            ],
          ),
        ),
      ),
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

  Widget? _buildSuggestionsOverlay(List<BusinessDto> businesses) {
    final matchingAutocomplete = _showAutocomplete
        ? businesses.where((b) => b.businessName.toLowerCase().contains(_searchController.text.toLowerCase())).toList()
        : <BusinessDto>[];

    if (!_showAutocomplete || matchingAutocomplete.isEmpty) return null;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: _HomeTok.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _HomeTok.border),
        boxShadow: [
          BoxShadow(
            color: _HomeTok.charcoal.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Quick Suggestions',
              style: TextStyle(
                fontFamily: 'Inter',
                color: _HomeTok.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1, color: _HomeTok.border),
          ...matchingAutocomplete.take(4).map(
            (b) => ListTile(
              leading: const Icon(Icons.search_rounded, color: _HomeTok.mutedText, size: 16),
              title: Text(
                b.businessName,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: _HomeTok.charcoal,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                b.categoryName ?? b.city,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: _HomeTok.medText,
                  fontSize: 11,
                ),
              ),
              onTap: () {
                HapticFeedback.lightImpact();
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(sortedCategoriesProvider);
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

    // Determine real user name and profile picture (reactive)
    final profileData = userProfileAsync.asData?.value;
    final userName = (profileData?.fullName.isNotEmpty == true) ? profileData!.fullName : 'User';
    final profilePicture = (profileData?.profilePicture != null && profileData!.profilePicture!.isNotEmpty) 
        ? profileData.profilePicture 
        : null;

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
        backgroundColor: _HomeTok.white,
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ─── 1. HEADER BAR ───
              SliverToBoxAdapter(
                child: HomeHeader(
                  userName: userName,
                  profilePicture: profilePicture,
                  onProfileTap: () => context.push('/profile'),
                  onAIFeedTap: () => context.push('/for-you'),
                  onLogoutTap: () => ref.read(authProvider.notifier).logout(),
                ),
              ),

              // ─── 2. SEARCH BAR WITH AUTOCOMPLETE ───
              SliverToBoxAdapter(
                child: searchResultsAsync.maybeWhen(
                  data: (businesses) => HomeSearchBar(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onVoiceTap: _triggerVoiceSearch,
                    recentSearches: _recentSearches,
                    onSearchChanged: _onSearchChangedDebounced,
                    onClear: () {
                      _searchDebounce?.cancel();
                      _searchController.clear();
                      ref.read(searchQueryProvider.notifier).setQuery('');
                      setState(() {
                        _showAutocomplete = false;
                      });
                    },
                    suggestionsOverlay: _buildSuggestionsOverlay(businesses),
                    showHistory: _searchFocusNode.hasFocus && _searchController.text.isEmpty,
                  ),
                  orElse: () => HomeSearchBar(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onVoiceTap: _triggerVoiceSearch,
                    recentSearches: _recentSearches,
                    onSearchChanged: _onSearchChangedDebounced,
                    onClear: () {
                      _searchDebounce?.cancel();
                      _searchController.clear();
                      ref.read(searchQueryProvider.notifier).setQuery('');
                      setState(() {
                        _showAutocomplete = false;
                      });
                    },
                    showHistory: _searchFocusNode.hasFocus && _searchController.text.isEmpty,
                  ),
                ),
              ),

              // ─── 3. HERO BANNER ───
              SliverToBoxAdapter(
                child: HomeHeroBanner(
                  onTap: () {
                    // Triggers filter refresh or map explore
                    ref.read(searchQueryProvider.notifier).setQuery('');
                  },
                ),
              ),

              // ─── 4. MAIN CATEGORIES & SUB-CATEGORIES SECTION ───
              SliverToBoxAdapter(
                child: categoriesAsync.when(
                  data: (categories) => HomeCategoryChips(
                    categories: categories,
                    selectedCategoryId: queryState.selectedCategoryId,
                    selectedSubcategoryId: queryState.selectedSubcategoryId,
                    onCategoryChanged: (catId) {
                      if (catId == null) {
                        ref.read(searchQueryProvider.notifier).clearCategory();
                      } else {
                        ref.read(searchQueryProvider.notifier).setCategory(catId);
                        ref.read(categoryUsageProvider.notifier).increment(catId, 2);
                      }
                    },
                    onSubcategoryChanged: (subId) {
                      if (subId == null) {
                        ref.read(searchQueryProvider.notifier).clearSubcategory();
                      } else {
                        ref.read(searchQueryProvider.notifier).setSubcategory(subId);
                      }
                    },
                    categoryIconResolver: _getCategoryIcon,
                    subcategoryIconResolver: _getSubcategoryIcon,
                  ),
                  loading: () => const CategoryChipsSkeleton(),
                  error: (err, stack) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: AppStateWidget.error(
                      message: AppErrorFormatter.format(err),
                      onRetry: () => ref.invalidate(categoriesProvider),
                    ),
                  ),
                ),
              ),

              // ─── 5. SORT CONTROL ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Verified Businesses',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: _HomeTok.charcoal,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _openSortBottomSheet(queryState.sortBy),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 168),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: _HomeTok.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _HomeTok.primary.withValues(alpha: 0.28),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.swap_vert_rounded, color: _HomeTok.primary, size: 16),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    _sortLabelFor(queryState.sortBy),
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      color: _HomeTok.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.keyboard_arrow_down_rounded, color: _HomeTok.primary, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── 6. BUSINESS LISTINGS FEED ───
              searchResultsAsync.when(
                data: (businesses) {
                  if (businesses.isEmpty) {
                    return SliverToBoxAdapter(
                      child: AppStateWidget.empty(
                        title: 'No businesses nearby',
                        description:
                            'Try widening your search, changing the category, or clearing filters.',
                        icon: Icons.search_off_rounded,
                        onActionPressed: () {
                          ref.read(searchQueryProvider.notifier).setQuery('');
                          ref.read(searchQueryProvider.notifier).clearCategory();
                          _searchController.clear();
                        },
                        actionLabel: 'Clear filters',
                      ),
                    );
                  }

                  final feed = ref.watch(searchFeedProvider).asData?.value;
                  final showPagination = feed != null && feed.totalPages > 1;

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (showPagination && index == businesses.length) {
                            return _buildPaginationBar(feed);
                          }

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
                        childCount: businesses.length + (showPagination ? 1 : 0),
                      ),
                    ),
                  );
                },
                loading: () => const HomeFeedSkeleton(),
                error: (err, stack) => SliverToBoxAdapter(
                  child: AppErrorFormatter.isOfflineError(err) || ref.watch(isOfflineProvider)
                      ? AppStateWidget.offline(
                          onRetry: () => ref.invalidate(searchFeedProvider),
                        )
                      : AppStateWidget.error(
                          message: AppErrorFormatter.format(err),
                          onRetry: () => ref.invalidate(searchFeedProvider),
                        ),
                ),
              ),

              // Bottom Spacer (content clears fixed bottom navigation)
              const SliverToBoxAdapter(
                child: SizedBox(height: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationBar(SearchFeedState feed) {
    final page = feed.page;
    final totalPages = feed.totalPages;
    final isLoading = feed.isLoadingPage;

    List<int> pageNumbers() {
      if (totalPages <= 5) {
        return List.generate(totalPages, (i) => i + 1);
      }
      final start = (page - 2).clamp(1, totalPages - 4);
      return List.generate(5, (i) => start + i);
    }

    void go(int target) {
      if (isLoading) return;
      HapticFeedback.selectionClick();
      ref.read(searchFeedProvider.notifier).goToPage(target);
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    }

    Widget pageBtn({
      required IconData icon,
      required bool enabled,
      required VoidCallback onTap,
      required String tooltip,
    }) {
      return IconButton(
        tooltip: tooltip,
        onPressed: enabled && !isLoading ? onTap : null,
        icon: Icon(icon, size: 22),
        color: _HomeTok.primary,
        disabledColor: _HomeTok.mutedText.withValues(alpha: 0.4),
        visualDensity: VisualDensity.compact,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      child: Column(
        children: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: _HomeTok.primary,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: _HomeTok.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _HomeTok.border),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                pageBtn(
                  icon: Icons.first_page_rounded,
                  enabled: page > 1,
                  onTap: () => go(1),
                  tooltip: 'First page',
                ),
                pageBtn(
                  icon: Icons.chevron_left_rounded,
                  enabled: page > 1,
                  onTap: () => go(page - 1),
                  tooltip: 'Previous page',
                ),
                ...pageNumbers().map((n) {
                  final selected = n == page;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Material(
                      color: selected
                          ? _HomeTok.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: selected || isLoading ? null : () => go(n),
                        child: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          child: Text(
                            '$n',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                              color: selected ? _HomeTok.primary : _HomeTok.charcoal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                pageBtn(
                  icon: Icons.chevron_right_rounded,
                  enabled: page < totalPages,
                  onTap: () => go(page + 1),
                  tooltip: 'Next page',
                ),
                pageBtn(
                  icon: Icons.last_page_rounded,
                  enabled: page < totalPages,
                  onTap: () => go(totalPages),
                  tooltip: 'Last page',
                ),
              ],
            ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            feed.totalCount > 0
                ? 'Page $page of $totalPages · ${feed.totalCount} businesses'
                : 'Page $page of $totalPages',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _HomeTok.medText,
            ),
          ),
        ],
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
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/business-detail/${business.businessId}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: _HomeTok.surface,
          border: Border.all(
            color: _HomeTok.border,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _HomeTok.charcoal.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
                      color: Color(0xFFF0EFEA),
                    ),
                    child: OptimizedNetworkImage.business(
                      imageUrl: business.photos.isNotEmpty ? business.photos.first : null,
                      height: 150,
                      width: double.infinity,
                      iconColor: _HomeTok.primary,
                      iconSize: 45,
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.4),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.5),
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
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.near_me_rounded, color: _HomeTok.primary, size: 12),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: Text(
                              locationText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                        HapticFeedback.mediumImpact();
                        ref.read(favoritesProvider.notifier).toggleFavorite(business.businessId);
                        if (!isFav) {
                          ref.read(categoryUsageProvider.notifier).increment(business.categoryId, 3);
                        }
                      },
                      child: AnimatedScale(
                        scale: isFav ? 1.25 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.elasticOut,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFav ? const Color(0xFFE1251B) : Colors.white,
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
                              fontFamily: 'Inter',
                              color: _HomeTok.charcoal,
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
                            color: const Color(0xFF1E824C).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF1E824C).withValues(alpha: 0.25)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified_rounded, color: Color(0xFF1E824C), size: 12),
                              SizedBox(width: 4),
                              Text(
                                'Verified',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: Color(0xFF1E824C),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      business.description,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: _HomeTok.medText,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Flexible(
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                business.averageRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  color: _HomeTok.charcoal,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '(${business.reviewCount} reviews)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: _HomeTok.mutedText,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Icon(Icons.call_rounded, color: _HomeTok.primary, size: 13),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  business.phoneNumber.isNotEmpty ? business.phoneNumber : 'Contact',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: _HomeTok.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
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
}
