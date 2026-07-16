import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import '../../providers/business_provider.dart';
import '../../data/models/business_models.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/providers/auth_state.dart';

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

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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
          const SnackBar(content: Text('Review submitted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit review: $e')),
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
          backgroundColor: Color(0xFFFF4D4F),
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
              backgroundColor: Color(0xFFFF4D4F),
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
            backgroundColor: const Color(0xFFFF4D4F),
          ),
        );
      }
    }
  }

  void _showSuggestionsBottomSheet(List<String> suggestions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Color(0xFFFF7A00)),
                  SizedBox(width: 8),
                  Text('AI Enhanced Reviews', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              const Text('Tap a suggestion below to apply it to your review:', style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 15),
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
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Text(suggestion, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
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
      backgroundColor: const Color(0xFF0F0E0D),
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
                backgroundColor: const Color(0xFF0F0E0D),
                leadingWidth: 56,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 14, top: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                          onPressed: () => context.pop(),
                        ),
                      ),
                    ),
                  ),
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
                                color: const Color(0xFF1E1C1A),
                                child: const Icon(Icons.storefront_rounded, color: Color(0xFFFF6B00), size: 60),
                              ),
                            )
                          : Container(
                              color: const Color(0xFF1E1C1A),
                              child: const Icon(Icons.storefront_rounded, color: Color(0xFFFF6B00), size: 60),
                            ),
                      // Top & Bottom gradient mask for text visibility
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.6),
                                Colors.transparent,
                                const Color(0xFF0F0E0D),
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
                                      color: Colors.white,
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
                                            color: Color(0xFFFF8C00),
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
                                          color: Colors.white.withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
                                        const Icon(Icons.location_on_rounded, color: Color(0xFFFF6B00), size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${business.distance!.toStringAsFixed(1)} km away',
                                          style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold),
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
                                color: const Color(0xFF1C1917),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFF6B00).withValues(alpha: 0.15)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: Color(0xFFFF8C00), size: 18),
                                      const SizedBox(width: 2),
                                      Text(
                                        business.averageRating.toStringAsFixed(1),
                                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${business.reviewCount} reviews',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10),
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
                              color: Colors.redAccent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Temporarily Closed',
                                      style: TextStyle(
                                        color: Colors.redAccent,
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
                                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
                                  ),
                                ],
                                if (business.temporaryClosureReopenDate != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Expected Reopening: ${_formatReopenDate(business.temporaryClosureReopenDate!)}',
                                    style: const TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic),
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
                              child: _buildActionBtn(Icons.phone_rounded, 'Call', () async {
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
                              }),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionBtn(Icons.directions_rounded, 'Directions', () async {
                                _incrementClickCount();
                                if (business.latitude != null && business.longitude != null) {
                                  try {
                                    final String url;
                                    if (Platform.isIOS) {
                                      url = 'https://maps.apple.com/?daddr=${business.latitude},${business.longitude}&dirflg=d';
                                    } else {
                                      url = 'https://www.google.com/maps/dir/?api=1&destination=${business.latitude},${business.longitude}&travelmode=driving';
                                    }
                                    final uri = Uri.parse(url);
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Could not launch map directions.')),
                                      );
                                    }
                                  }
                                } else {
                                  // Fallback: Use address if coordinates are missing
                                  final address = '${business.address}, ${business.city}, ${business.state}, ${business.country}'.trim();
                                  if (address.isNotEmpty && address != ', , , ') {
                                    try {
                                      final String url;
                                      if (Platform.isIOS) {
                                        url = 'https://maps.apple.com/?daddr=${Uri.encodeComponent(address)}&dirflg=d';
                                      } else {
                                        url = 'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(address)}&travelmode=driving';
                                      }
                                      final uri = Uri.parse(url);
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Could not launch map directions.')),
                                        );
                                      }
                                    }
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Business location not available. Please contact the business owner.')),
                                      );
                                    }
                                  }
                                }
                              }),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionBtn(Icons.language_rounded, 'Website', () async {
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
                                      backgroundColor: Color(0xFFFF4D4F),
                                    ),
                                  );
                                }
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Master Detail Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141210),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFFF6B00).withValues(alpha: 0.08),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // About Section
                              const Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, color: Color(0xFFFF6B00), size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'About',
                                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                business.description,
                                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                              ),
                              const Divider(color: Colors.white10, height: 32),

                              // Location Section
                              const Row(
                                children: [
                                  Icon(Icons.location_on_outlined, color: Color(0xFFFF6B00), size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Location',
                                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                business.address,
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${business.city}, ${business.state}, ${business.country} - ${business.pincode}',
                                style: const TextStyle(color: Colors.white38, fontSize: 12),
                              ),
                              const Divider(color: Colors.white10, height: 32),

                              // Operating Hours Section
                              const Row(
                                children: [
                                  Icon(Icons.access_time_rounded, color: Color(0xFFFF6B00), size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Operating Hours',
                                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              business.hours.isEmpty
                                  ? const Text('Hours not registered', style: TextStyle(color: Colors.white38, fontSize: 13))
                                  : Column(
                                      children: business.hours.map((h) {
                                        final slotsStr = h.slots.map((s) => '${s.open} - ${s.close}').join(', ');
                                        final isClosed = h.mode.toLowerCase() == 'closed';
                                        return Container(
                                          margin: const EdgeInsets.symmetric(vertical: 4),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1E1A17).withValues(alpha: 0.4),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  _formatDays(h.day),
                                                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                              Text(
                                                isClosed ? 'Closed' : (slotsStr.isNotEmpty ? _formatSlots(h.slots) : 'Open'),
                                                style: TextStyle(
                                                  color: isClosed ? Colors.redAccent : const Color(0xFF4ADE80),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
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
                              color: const Color(0xFF141210),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFFF6B00).withValues(alpha: 0.1)),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ] else if (_aiSummary.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1A17).withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFFF6B00).withValues(alpha: 0.25)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF6B00).withValues(alpha: 0.04),
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFF8C00), size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'AI Reviews Summary',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.95),
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
                                    color: Colors.white70,
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
                          const Divider(color: Colors.white10, height: 32),
                          const Text(
                            'Write a Review',
                            style: TextStyle(color: Color(0xFFFF7A00), fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141210),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Rating', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                    DropdownButton<double>(
                                      value: _userRating,
                                      dropdownColor: const Color(0xFF1C1917),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      underline: const SizedBox.shrink(),
                                      items: [5.0, 4.0, 3.0, 2.0, 1.0].map((val) {
                                        return DropdownMenuItem<double>(
                                          value: val,
                                          child: Row(
                                            children: [
                                              Text(val.toStringAsFixed(0)),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.star_rounded, color: Color(0xFFFF8C00), size: 16),
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
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'Share your experience with this business...',
                                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                                    filled: true,
                                    fillColor: const Color(0xFF1E1C1A).withValues(alpha: 0.5),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFFF6B00)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Image picker for reviews
                                if (_pickedImage != null) ...[
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
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
                                      icon: const Icon(Icons.add_a_photo_rounded, color: Color(0xFFFF8C00)),
                                      onPressed: _pickImage,
                                      tooltip: 'Add Photo',
                                    ),
                                    const Spacer(),
                                    TextButton.icon(
                                      icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                                      label: const Text('Improve with AI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(0xFFFF8C00),
                                      ),
                                      onPressed: _loadingAISuggestions ? null : () => _getAISuggestions(business.businessName),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: _isSubmittingReview ? null : _submitReview,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFF6B00),
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
                        const Divider(color: Colors.white10, height: 32),
                        const Text(
                          'User Reviews',
                          style: TextStyle(color: Color(0xFFFF7A00), fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),

                        reviewsAsync.when(
                          data: (reviews) {
                            if (reviews.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text('No reviews yet. Be the first to share your thoughts!', style: TextStyle(color: Colors.white38, fontSize: 13)),
                                ),
                              );
                            }

                            return Column(
                              children: reviews.map((r) => _buildReviewCard(r)).toList(),
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A00))),
                          error: (err, st) => Text('Error loading reviews: $err', style: const TextStyle(color: Colors.redAccent)),
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
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A00))),
        error: (err, st) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1A17).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B00).withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFFF8C00), size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(BusinessReviewDto review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                review.userName,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    Icons.star,
                    color: index < review.rating ? const Color(0xFFFF7A00) : Colors.white12,
                    size: 14,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.comment,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
          ),
          if (review.imageUrl != null && review.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                review.imageUrl!.startsWith('http')
                    ? review.imageUrl!
                    : '${DioClient().dio.options.baseUrl.replaceAll('/api/v1/', '')}${review.imageUrl}',
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDays(String dayStr) {
    if (dayStr.contains(',')) {
      final days = dayStr.split(',');
      if (days.length == 7) return 'Everyday';
      if (days.length == 5 && days.contains('Monday') && days.contains('Friday')) {
        return 'Weekdays (Mon - Fri)';
      }
      if (days.length == 2 && days.contains('Saturday') && days.contains('Sunday')) {
        return 'Weekends (Sat - Sun)';
      }
      return days.map((d) => d.trim().substring(0, 3)).join(', ');
    }
    return dayStr;
  }

  String _formatSlots(List<dynamic> slots) {
    return slots.map((s) {
      final open = _formatTime(s.open);
      final close = _formatTime(s.close);
      return '$open - $close';
    }).join(', ');
  }

  String _formatTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        final displayMinute = minute.toString().padLeft(2, '0');
        return '$displayHour:$displayMinute $period';
      }
    } catch (_) {}
    return timeStr;
  }

  String _formatReopenDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final local = date.toLocal();
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }
}
