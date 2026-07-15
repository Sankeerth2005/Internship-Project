import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
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
      backgroundColor: const Color(0xFF0F0F0F),
      body: businessAsync.when(
        data: (business) {

          return CustomScrollView(
            slivers: [
              // Header Image Banner
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: const Color(0xFF1E1E1E),
                leading: CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: business.photos.isNotEmpty
                      ? Image.network(
                          '${Uri.parse(DioClient().dio.options.baseUrl).origin}${business.photos.first}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, err, st) => Container(
                            color: const Color(0xFF2E2E2E),
                            child: const Icon(Icons.store, color: Color(0xFFFF7A00), size: 60),
                          ),
                        )
                      : Container(
                          color: const Color(0xFF2E2E2E),
                          child: const Icon(Icons.store, color: Color(0xFFFF7A00), size: 60),
                        ),
                ),
              ),

              // Content details
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (business.categoryName != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      business.categoryName!,
                                      style: const TextStyle(color: Color(0xFFFF7A00), fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Color(0xFFFF7A00), size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  business.averageRating.toStringAsFixed(1),
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  ' (${business.reviewCount})',
                                  style: const TextStyle(color: Colors.white38, fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        if (business.isTemporarilyClosed) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(15),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Temporarily Closed',
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                if (business.temporaryClosureReason != null && business.temporaryClosureReason!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Reason: ${business.temporaryClosureReason}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                                  ),
                                ],
                                if (business.temporaryClosureReopenDate != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Expected Reopening: ${_formatReopenDate(business.temporaryClosureReopenDate!)}',
                                    style: const TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildActionBtn(Icons.phone, 'Call', () async {
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
                            _buildActionBtn(Icons.directions, 'Directions', () async {
                              _incrementClickCount();
                              if (business.latitude != null && business.longitude != null) {
                                final String url;
                                if (Platform.isIOS) {
                                  url = 'https://maps.apple.com/?daddr=${business.latitude},${business.longitude}&dirflg=d';
                                } else {
                                  url = 'google.navigation:q=${business.latitude},${business.longitude}';
                                }
                                try {
                                  final uri = Uri.parse(url);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri);
                                  } else {
                                    final fallbackUrl = 'https://www.google.com/maps/dir/?api=1&destination=${business.latitude},${business.longitude}&travelmode=driving';
                                    await launchUrl(Uri.parse(fallbackUrl), mode: LaunchMode.externalApplication);
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Could not launch map directions.')),
                                    );
                                  }
                                }
                              } else {

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Business coordinates not registered.')),
                                );
                              }
                            }),
                            _buildActionBtn(Icons.language, 'Website', () async {
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
                          ],
                        ),
                        const SizedBox(height: 25),

                        const Text(
                          'About',
                          style: TextStyle(color: Color(0xFFFF7A00), fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          business.description,
                          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                        ),
                        const SizedBox(height: 25),

                        const Text(
                          'Location',
                          style: TextStyle(color: Color(0xFFFF7A00), fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFFFF7A00), size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    business.address,
                                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${business.city}, ${business.state}, ${business.country} - ${business.pincode}',
                                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),

                        // Hours Accordion
                        const Text(
                          'Operating Hours',
                          style: TextStyle(color: Color(0xFFFF7A00), fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        business.hours.isEmpty
                            ? const Text('Hours not registered', style: TextStyle(color: Colors.white38, fontSize: 13))
                            : Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: business.hours.map((h) {
                                    final slotsStr = h.slots.map((s) => '${s.open} - ${s.close}').join(', ');
                                    final isClosed = h.mode.toLowerCase() == 'closed';
                                    return Container(
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E1E1E),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.calendar_month, color: Color(0xFFFF7A00), size: 16),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  _formatDays(h.day),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(Icons.access_time, color: Colors.white38, size: 16),
                                              const SizedBox(width: 8),
                                              Text(
                                                isClosed ? 'Closed' : (slotsStr.isNotEmpty ? _formatSlots(h.slots) : 'Open'),
                                                style: TextStyle(
                                                  color: isClosed ? Colors.redAccent : Colors.greenAccent,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                        const SizedBox(height: 30),

                        if (isClient) ...[
                          const Divider(color: Colors.white10),
                          const SizedBox(height: 20),

                          // Add Review Form
                          const Text(
                            'Write a Review',
                            style: TextStyle(color: Color(0xFFFF7A00), fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text('Rating: ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                    const SizedBox(width: 5),
                                    // Star select popup
                                    DropdownButton<double>(
                                      dropdownColor: const Color(0xFF1E1E1E),
                                      value: _userRating,
                                      items: [5.0, 4.0, 3.0, 2.0, 1.0].map((val) {
                                        return DropdownMenuItem<double>(
                                          value: val,
                                          child: Row(
                                            children: [
                                              const Icon(Icons.star, color: Color(0xFFFF7A00), size: 16),
                                              const SizedBox(width: 4),
                                              Text(val.toStringAsFixed(0), style: const TextStyle(color: Colors.white)),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (rating) {
                                        if (rating != null) setState(() => _userRating = rating);
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _commentController,
                                  style: const TextStyle(color: Colors.white),
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                    hintText: 'Share details of your own experience at this place...',
                                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                                    filled: true,
                                    fillColor: Colors.black38,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: _pickImage,
                                      icon: const Icon(Icons.add_photo_alternate, color: Color(0xFFFF7A00), size: 16),
                                      label: const Text('Add Image', style: TextStyle(color: Color(0xFFFF7A00), fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Color(0xFFFF7A00)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                    if (_pickedImage != null) ...[
                                      const SizedBox(width: 12),
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.file(
                                              _pickedImage!,
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Positioned(
                                            top: -6,
                                            right: -6,
                                            child: GestureDetector(
                                              onTap: _clearImage,
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: const BoxDecoration(
                                                  color: Colors.redAccent,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.close, color: Colors.white, size: 12),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _loadingAISuggestions
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Color(0xFFFF7A00)),
                                          )
                                        : TextButton.icon(
                                            icon: const Icon(Icons.auto_awesome,
                                                color: Color(0xFFFF7A00), size: 16),
                                            label: const Text('AI Enhance',
                                                style: TextStyle(
                                                    color: Color(0xFFFF7A00),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold)),
                                            onPressed: () =>
                                                _getAISuggestions(business.businessName),
                                          ),
                                    SizedBox(
                                      height: 35,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFFF7A00),
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(horizontal: 24),
                                        ),
                                        onPressed: _isSubmittingReview ? null : _submitReview,
                                        child: _isSubmittingReview
                                            ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                            : const Text('Post', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],

                        reviewsAsync.when(
                          data: (reviews) {
                            if (reviews.isNotEmpty && _aiSummary.isEmpty && !_loadingSummary) {
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
                          const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFFFF7A00)),
                          ),
                          const SizedBox(height: 20),
                        ] else if (_aiSummary.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFFF7A00).withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.auto_awesome,
                                        color: Color(0xFFFF7A00), size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'AI Reviews Summary',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _aiSummary,
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      height: 1.4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Reviews List header
                        const Text(
                          'User Reviews',
                          style: TextStyle(color: Color(0xFFFF7A00), fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 15),

                        reviewsAsync.when(
                          data: (reviews) {
                            if (reviews.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Text('No reviews yet. Be the first to add one!', style: TextStyle(color: Colors.white38, fontSize: 13)),
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
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Icon(icon, color: const Color(0xFFFF7A00), size: 20),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
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
