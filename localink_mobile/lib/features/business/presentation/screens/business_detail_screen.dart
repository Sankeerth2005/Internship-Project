import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

import '../../providers/business_provider.dart';
import '../../data/models/business_models.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/signalr_service.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/providers/auth_state.dart';
import '../../widgets/business_action_button.dart';
import '../../widgets/business_operating_hours.dart';
import '../../widgets/business_review_card.dart';
import '../../../shared/presentation/widgets/app_back_button.dart';

// ─── DESIGN TOKENS ────────────────────────────────────────────────────────────
class _DetailTok {
  static const Color primary = Color(0xFFFF6600);
  static const Color bg = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFF9F8F6);
  static const Color border = Color(0xFFEAE8E3);
  static const Color textHigh = Color(0xFF1A1918);
  static const Color textMedium = Color(0xFF5F5C58);
  static const Color textLow = Color(0xFF9F9B96);
}

class BusinessDetailScreen extends ConsumerStatefulWidget {
  final int businessId;
  const BusinessDetailScreen({super.key, required this.businessId});

  @override
  ConsumerState<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends ConsumerState<BusinessDetailScreen> {
  final _commentController = TextEditingController();
  double _userRating = 5.0;
  bool _isSubmittingReview = false;
  File? _pickedImage;
  String? _base64Image;

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _pickedImage = File(pickedFile.path);
          _base64Image = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _clearImage() {
    setState(() {
      _pickedImage = null;
      _base64Image = null;
    });
  }

  // AI Review Features State
  String _aiSummary = '';
  bool _loadingSummary = false;
  bool _loadingAISuggestions = false;

  @override
  void initState() {
    super.initState();
    _incrementViewCount();
    SignalRService().addNotificationListener(_onNotificationReceived);
  }

  @override
  void dispose() {
    SignalRService().removeNotificationListener(_onNotificationReceived);
    _commentController.dispose();
    super.dispose();
  }

  void _onNotificationReceived(String message) {
    if (message.contains('BusinessUpdated:${widget.businessId}') ||
        message.contains('BusinessDeleted:${widget.businessId}') ||
        message.contains('status') ||
        message.contains('closure')) {
      ref.invalidate(singleBusinessProvider(widget.businessId));
    }
  }

  Future<void> _incrementViewCount() async {
    try {
      await DioClient().dio.post('analytics/business/${widget.businessId}/view');
    } catch (_) {}
  }

  Future<void> _incrementClickCount() async {
    try {
      await DioClient().dio.post('analytics/business/${widget.businessId}/click');
    } catch (_) {}
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSubmittingReview = true);

    try {
      final repo = ref.read(businessRepositoryProvider);
      await repo.addReview(
        widget.businessId,
        _userRating,
        _commentController.text.trim(),
        image: _base64Image,
      );

      // Reset AI summary so it is re-fetched next time
      _aiSummary = '';

      // Refresh reviews list
      ref.invalidate(reviewsProvider(widget.businessId));
      
      if (mounted) {
        _commentController.clear();
        _clearImage();
        setState(() => _userRating = 5.0);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!'), backgroundColor: Color(0xFF1E824C)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit review: $e'), backgroundColor: const Color(0xFFE1251B)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingReview = false);
    }
  }

  Future<void> _getAISuggestions(String bizName) async {
    final draft = _commentController.text.trim();
    if (draft.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write at least a few words to enhance.'),
          backgroundColor: Color(0xFFE1251B),
        ),
      );
      return;
    }

    setState(() => _loadingAISuggestions = true);
    try {
      final repo = ref.read(businessRepositoryProvider);
      final suggestions = await repo.getReviewSuggestions(
        draft,
        _userRating.toInt(),
        bizName,
      );

      setState(() => _loadingAISuggestions = false);

      if (suggestions.isNotEmpty && mounted) {
        _showSuggestionsBottomSheet(suggestions);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No suggestions returned from AI.'),
              backgroundColor: Color(0xFFE1251B),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingAISuggestions = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get suggestions: $e'),
            backgroundColor: const Color(0xFFE1251B),
          ),
        );
      }
    }
  }

  void _showSuggestionsBottomSheet(List<String> suggestions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _DetailTok.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: _DetailTok.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'AI Enhanced Reviews',
                    style: TextStyle(
                      color: _DetailTok.textHigh,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Tap a suggestion below to apply it to your review:',
                style: TextStyle(color: _DetailTok.textMedium, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: suggestions.length,
                  itemBuilder: (context, idx) {
                    final suggestion = suggestions[idx];
                    return GestureDetector(
                      onTap: () {
                        _commentController.text = suggestion;
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _DetailTok.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _DetailTok.border),
                        ),
                        child: Text(
                          suggestion,
                          style: const TextStyle(
                            color: _DetailTok.textMedium,
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _fetchAISummary(List<BusinessReviewDto> reviews, String bizName, double avgRating, int totalReviews) async {
    if (reviews.isEmpty || _aiSummary.isNotEmpty || _loadingSummary) return;

    setState(() => _loadingSummary = true);
    try {
      final repo = ref.read(businessRepositoryProvider);
      final reviewTexts = reviews.map((r) => r.comment).toList();
      final summary = await repo.getReviewSummary(
        reviewTexts,
        avgRating,
        totalReviews,
        bizName,
      );
      setState(() {
        _aiSummary = summary;
        _loadingSummary = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingSummary = false);
        debugPrint('Failed to fetch AI summary: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessAsync = ref.watch(singleBusinessProvider(widget.businessId));
    final reviewsAsync = ref.watch(reviewsProvider(widget.businessId));
    final authState = ref.watch(authProvider);
    final isClient = authState is AuthAuthenticated && authState.userType.toLowerCase().trim() == 'user';

    return Scaffold(
      backgroundColor: _DetailTok.bg,
      body: businessAsync.when(
        data: (business) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Parallax Header Image Banner
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                stretch: true,
                backgroundColor: _DetailTok.bg,
                leadingWidth: 70,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                  child: AppBackButton(onPressed: () => context.pop()),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      business.photos.isNotEmpty
                          ? Image.network(
                              '${Uri.parse(DioClient().dio.options.baseUrl).origin}${business.photos.first}',
                              fit: BoxFit.cover,
                              errorBuilder: (context, err, st) => Container(
                                color: const Color(0xFFF5F4F0),
                                child: const Icon(Icons.storefront_rounded, color: _DetailTok.primary, size: 60),
                              ),
                            )
                          : Container(
                              color: const Color(0xFFF5F4F0),
                              child: const Icon(Icons.storefront_rounded, color: _DetailTok.primary, size: 60),
                            ),
                      // Top & Bottom gradient mask for text visibility
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.3),
                                Colors.transparent,
                                _DetailTok.bg,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content details
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title, Category & Star Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    business.businessName,
                                    style: const TextStyle(
                                      color: _DetailTok.textHigh,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      if (business.categoryName != null) ...[
                                        Text(
                                          business.categoryName!,
                                          style: const TextStyle(
                                            color: _DetailTok.primary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      // Ashok Chakra Tricolor Pill
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF9F8F6),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: const Color(0xFFEAE8E3)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(width: 5, height: 8, color: const Color(0xFFFF9933)),
                                            Container(width: 5, height: 8, color: Colors.white),
                                            Container(width: 5, height: 8, color: const Color(0xFF138808)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (business.distance != null) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_rounded, color: _DetailTok.primary, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${business.distance!.toStringAsFixed(1)} km away',
                                          style: const TextStyle(
                                            color: _DetailTok.textMedium,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Ratings Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7F2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _DetailTok.primary.withValues(alpha: 0.15)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: _DetailTok.primary, size: 18),
                                      const SizedBox(width: 2),
                                      Text(
                                        business.averageRating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          color: _DetailTok.textHigh,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${business.reviewCount} reviews',
                                    style: const TextStyle(color: _DetailTok.textMedium, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Temporary Closure Warning
                        if (business.isTemporarilyClosed) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF2F2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.error_outline_rounded, color: Color(0xFFE1251B), size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Temporarily Closed',
                                      style: TextStyle(
                                        color: Color(0xFFE1251B),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                if (business.temporaryClosureReason != null && business.temporaryClosureReason!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Reason: ${business.temporaryClosureReason}',
                                    style: const TextStyle(color: _DetailTok.textMedium, fontSize: 13, height: 1.3),
                                  ),
                                ],
                                if (business.temporaryClosureReopenDate != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Expected Reopening: ${_formatReopenDate(business.temporaryClosureReopenDate!)}',
                                    style: const TextStyle(color: _DetailTok.textLow, fontSize: 12, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],

                        // Futuristic Glowing Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: BusinessActionButton(
                                icon: Icons.phone_rounded,
                                label: 'Call',
                                onTap: () async {
                                  _incrementClickCount();
                                  final cleanCode = business.phoneCode.replaceAll('+', '').trim();
                                  final cleanNum = business.phoneNumber.trim();
                                  if (cleanNum.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Phone number not available.')),
                                    );
                                    return;
                                  }
                                  try {
                                    await launchUrl(Uri.parse('tel:+$cleanCode$cleanNum'));
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Could not start phone call.')),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: BusinessActionButton(
                                icon: Icons.directions_rounded,
                                label: 'Directions',
                                onTap: () async {
                                  _incrementClickCount();
                                  Position? userPos;
                                  try {
                                    LocationPermission permission = await Geolocator.checkPermission();
                                    if (permission == LocationPermission.denied) {
                                      permission = await Geolocator.requestPermission();
                                    }
                                    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
                                      userPos = await Geolocator.getCurrentPosition(
                                        locationSettings: const LocationSettings(
                                          accuracy: LocationAccuracy.medium,
                                          timeLimit: Duration(seconds: 5),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    debugPrint('Error getting user location for directions: $e');
                                  }

                                  final lat = business.latitude;
                                  final lng = business.longitude;

                                  if (lat != null &&
                                      lng != null &&
                                      lat >= -90.0 &&
                                      lat <= 90.0 &&
                                      lng >= -180.0 &&
                                      lng <= 180.0 &&
                                      lat != 0.0 &&
                                      lng != 0.0 &&
                                      !lat.isNaN &&
                                      !lng.isNaN) {
                                    try {
                                      final String url;
                                      if (Platform.isIOS) {
                                        if (userPos != null) {
                                          url = 'https://maps.apple.com/?saddr=${userPos.latitude},${userPos.longitude}&daddr=$lat,$lng&dirflg=d';
                                        } else {
                                          url = 'https://maps.apple.com/?daddr=$lat,$lng&dirflg=d';
                                        }
                                      } else {
                                        if (userPos != null) {
                                          url = 'https://www.google.com/maps/dir/?api=1&origin=${userPos.latitude},${userPos.longitude}&destination=$lat,$lng&travelmode=driving';
                                        } else {
                                          url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
                                        }
                                      }
                                      final uri = Uri.parse(url);
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    } catch (e) {
                                      debugPrint('Error launching map directions URL: $e');
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Could not launch map application.')),
                                        );
                                      }
                                    }
                                  } else {
                                    debugPrint('Navigation validation failed for business "${business.businessName}" (ID: ${business.businessId}). Coordinates: Lat=$lat, Lng=$lng');
                                    if (context.mounted) {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Row(
                                            children: [
                                              Icon(Icons.error_outline, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Navigation Failed'),
                                            ],
                                          ),
                                          content: const Text(
                                            'This business has invalid or uninitialized coordinates. Navigation cannot be launched until the business owner updates the location.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: BusinessActionButton(
                                icon: Icons.language_rounded,
                                label: 'Website',
                                onTap: () async {
                                  _incrementClickCount();
                                  if (business.website.trim().isNotEmpty) {
                                    try {
                                      var urlStr = business.website.trim();
                                      if (!urlStr.startsWith('http://') && !urlStr.startsWith('https://')) {
                                        urlStr = 'https://$urlStr';
                                      }
                                      await launchUrl(Uri.parse(urlStr), mode: LaunchMode.externalApplication);
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Could not open website.')),
                                        );
                                      }
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Website not present'),
                                        backgroundColor: Color(0xFFE1251B),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Master Detail Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _DetailTok.cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _DetailTok.border,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // About Section
                              const Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, color: _DetailTok.primary, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'About',
                                    style: TextStyle(color: _DetailTok.textHigh, fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                business.description,
                                style: const TextStyle(color: _DetailTok.textMedium, fontSize: 13, height: 1.45),
                              ),
                              const Divider(color: _DetailTok.border, height: 32),

                              // Location Section
                              const Row(
                                children: [
                                  Icon(Icons.location_on_outlined, color: _DetailTok.primary, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Location',
                                    style: TextStyle(color: _DetailTok.textHigh, fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                business.address,
                                style: const TextStyle(color: _DetailTok.textHigh, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${business.city}, ${business.state}, ${business.country} - ${business.pincode}',
                                style: const TextStyle(color: _DetailTok.textMedium, fontSize: 12),
                              ),
                              const Divider(color: _DetailTok.border, height: 32),

                              // Operating Hours Section
                              const Row(
                                children: [
                                  Icon(Icons.access_time_rounded, color: _DetailTok.primary, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Operating Hours',
                                    style: TextStyle(color: _DetailTok.textHigh, fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              BusinessOperatingHours(hours: business.hours),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // AI Review Trigger & Display
                        reviewsAsync.when(
                          data: (reviews) {
                            if (reviews.isNotEmpty) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _fetchAISummary(
                                  reviews,
                                  business.businessName,
                                  business.averageRating,
                                  business.reviewCount,
                                );
                              });
                            }
                            return const SizedBox.shrink();
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (err, st) => const SizedBox.shrink(),
                        ),

                        if (_loadingSummary) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: _DetailTok.cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _DetailTok.primary.withValues(alpha: 0.15)),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(color: _DetailTok.primary),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ] else if (_aiSummary.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7F2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _DetailTok.primary.withValues(alpha: 0.22)),
                              boxShadow: [
                                BoxShadow(
                                  color: _DetailTok.primary.withValues(alpha: 0.02),
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.auto_awesome_rounded, color: _DetailTok.primary, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'AI Reviews Summary',
                                      style: TextStyle(
                                        color: _DetailTok.textHigh,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _aiSummary,
                                  style: const TextStyle(
                                    color: _DetailTok.textMedium,
                                    fontSize: 13,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Write review form (For regular user login)
                        if (isClient) ...[
                          const Divider(color: _DetailTok.border, height: 32),
                          const Text(
                            'Write a Review',
                            style: TextStyle(color: _DetailTok.primary, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _DetailTok.cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _DetailTok.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Rating', style: TextStyle(color: _DetailTok.textMedium, fontSize: 13)),
                                    DropdownButton<double>(
                                      value: _userRating,
                                      dropdownColor: _DetailTok.bg,
                                      style: const TextStyle(color: _DetailTok.textHigh, fontWeight: FontWeight.bold),
                                      underline: const SizedBox.shrink(),
                                      items: [5.0, 4.0, 3.0, 2.0, 1.0].map((val) {
                                        return DropdownMenuItem<double>(
                                          value: val,
                                          child: Row(
                                            children: [
                                              Text(val.toStringAsFixed(0)),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.star_rounded, color: _DetailTok.primary, size: 16),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _userRating = val);
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _commentController,
                                  maxLines: 3,
                                  style: const TextStyle(color: _DetailTok.textHigh, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'Share your experience with this business...',
                                    hintStyle: const TextStyle(color: _DetailTok.textLow, fontSize: 13),
                                    filled: true,
                                    fillColor: _DetailTok.bg,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: _DetailTok.border),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: _DetailTok.border),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: _DetailTok.primary, width: 1.5),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Image picker for reviews
                                if (_pickedImage != null) ...[
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(_pickedImage!, width: double.infinity, height: 160, fit: BoxFit.cover),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: CircleAvatar(
                                          backgroundColor: Colors.black54,
                                          radius: 16,
                                          child: IconButton(
                                            icon: const Icon(Icons.close, size: 14, color: Colors.white),
                                            onPressed: _clearImage,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.add_a_photo_rounded, color: _DetailTok.primary),
                                      onPressed: _pickImage,
                                      tooltip: 'Add Photo',
                                    ),
                                    const Spacer(),
                                    TextButton.icon(
                                      icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                                      label: const Text('Improve with AI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      style: TextButton.styleFrom(
                                        foregroundColor: _DetailTok.primary,
                                      ),
                                      onPressed: _loadingAISuggestions ? null : () => _getAISuggestions(business.businessName),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: _isSubmittingReview ? null : _submitReview,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _DetailTok.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      child: _isSubmittingReview
                                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                          : const Text('Submit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],

                        // User Reviews List
                        const Divider(color: _DetailTok.border, height: 32),
                        const Text(
                          'User Reviews',
                          style: TextStyle(color: _DetailTok.primary, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),

                        reviewsAsync.when(
                          data: (reviews) {
                            if (reviews.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text(
                                    'No reviews yet. Be the first to share your thoughts!',
                                    style: TextStyle(color: _DetailTok.textLow, fontSize: 13),
                                  ),
                                ),
                              );
                            }

                            return Column(
                              children: reviews.map((r) => BusinessReviewCard(review: r)).toList(),
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator(color: _DetailTok.primary)),
                          error: (err, st) => Text('Error loading reviews: $err', style: const TextStyle(color: Color(0xFFE1251B))),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: _DetailTok.primary)),
        error: (err, st) => Center(child: Text('Error: $err', style: const TextStyle(color: Color(0xFFE1251B)))),
      ),
    );
  }

  String _formatReopenDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final local = date.toLocal();
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }
}
