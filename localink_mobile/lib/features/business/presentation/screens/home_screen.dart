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
import '../../../../core/network/dio_client.dart';
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
      backgroundColor: _HomeTok.white,
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
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: _HomeTok.charcoal,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: _HomeTok.medText),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: _HomeTok.border),
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
      leading: Icon(icon, color: isSelected ? _HomeTok.primary : _HomeTok.medText),
      title: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          color: isSelected ? _HomeTok.primary : _HomeTok.charcoal,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: _HomeTok.primary) : null,
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
        backgroundColor: _HomeTok.white,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ─── 1. HEADER BAR ───
              SliverToBoxAdapter(
                child: HomeHeader(
                  userName: userName,
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
                    onSearchChanged: (val) {
                      ref.read(searchQueryProvider.notifier).setQuery(val);
                      setState(() {
                        _showAutocomplete = val.length >= 3;
                      });
                    },
                    onClear: () {
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
                    onSearchChanged: (val) {
                      ref.read(searchQueryProvider.notifier).setQuery(val);
                      setState(() {
                        _showAutocomplete = val.length >= 3;
                      });
                    },
                    onClear: () {
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
                  loading: () => const SizedBox(
                    height: 120,
                    child: Center(
                      child: CircularProgressIndicator(color: _HomeTok.primary),
                    ),
                  ),
                  error: (err, stack) => const SizedBox.shrink(),
                ),
              ),

              // ─── 5. SORT BUTTON ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Verified Businesses',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: _HomeTok.charcoal,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _openSortBottomSheet(queryState.sortBy),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _HomeTok.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _HomeTok.primary.withValues(alpha: 0.25),
                              width: 1.2,
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.swap_vert_rounded, color: _HomeTok.primary, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Sort ⇅',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: _HomeTok.primary,
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

              // ─── 6. BUSINESS LISTINGS FEED ───
              searchResultsAsync.when(
                data: (businesses) {
                  if (businesses.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(50.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.search_off_rounded, color: _HomeTok.mutedText, size: 48),
                              SizedBox(height: 15),
                              Text(
                                'No local businesses found.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: _HomeTok.medText,
                                  fontSize: 14,
                                ),
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
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(50.0),
                    child: Center(
                      child: CircularProgressIndicator(color: _HomeTok.primary),
                    ),
                  ),
                ),
                error: (err, stack) => SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'Error: $err',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Spacer
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
                    child: business.photos.isNotEmpty
                        ? Image.network(
                            '${Uri.parse(DioClient().dio.options.baseUrl).origin}${business.photos.first}',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: const Color(0xFFF0EFEA),
                              child: const Icon(Icons.storefront_rounded, color: _HomeTok.primary, size: 45),
                            ),
                          )
                        : Container(
                            color: const Color(0xFFF0EFEA),
                            child: const Icon(Icons.storefront_rounded, color: _HomeTok.primary, size: 45),
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
                          Text(
                            locationText,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
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
                            Text(
                              '(${business.reviewCount} reviews)',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: _HomeTok.mutedText,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.call_rounded, color: _HomeTok.primary, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              business.phoneNumber.isNotEmpty ? business.phoneNumber : 'Contact',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: _HomeTok.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
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
