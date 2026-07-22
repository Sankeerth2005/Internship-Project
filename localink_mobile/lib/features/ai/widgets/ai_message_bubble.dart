import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../business/providers/business_provider.dart';
import '../../business/data/models/business_models.dart';

class AiMessageBubble extends ConsumerWidget {
  final String content;
  final bool isUser;

  const AiMessageBubble({
    super.key,
    required this.content,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isUser) {
      return _buildUserBubble(context);
    }

    final allBusinessesAsync = ref.watch(allBusinessesProvider);

    return allBusinessesAsync.when(
      data: (businesses) {
        final matched = <BusinessDto>[];
        final lowerText = content.toLowerCase();

        for (final b in businesses) {
          if (b.businessName.length >= 4 &&
              (lowerText.contains(b.businessName.toLowerCase()) ||
                  lowerText.contains('[${b.businessName.toLowerCase()}]'))) {
            matched.add(b);
          }
        }

        return _buildAiBubbleWithMatches(context, ref, matched);
      },
      loading: () => _buildAiBubbleWithMatches(context, ref, []),
      error: (error, stack) => _buildAiBubbleWithMatches(context, ref, []),
    );
  }

  Widget _buildUserBubble(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFFF6600),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.zero,
                ),
              ),
              child: Text(
                content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F8F6),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFEAE8E3)),
            ),
            child: const Icon(Icons.person, color: Color(0xFF5F5C58), size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildAiBubbleWithMatches(BuildContext context, WidgetRef ref, List<BusinessDto> matched) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6600).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xFFFF6600), size: 16),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F8F6),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.zero,
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(color: const Color(0xFFEAE8E3)),
                  ),
                  child: Text(
                    content,
                    style: const TextStyle(
                      color: Color(0xFF1A1918),
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (matched.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: matched.map((b) => _buildMatchedBusinessCard(context, ref, b)).toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMatchedBusinessCard(BuildContext context, WidgetRef ref, BusinessDto b) {
    final favorites = ref.watch(favoritesProvider);
    final isFav = favorites.contains(b.businessId);

    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAE8E3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: b.photos.isNotEmpty
                ? Image.network(
                    b.photos.first,
                    height: 80,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 80,
                    color: const Color(0xFFF9F8F6),
                    child: const Center(
                      child: Icon(Icons.storefront_rounded, color: Color(0xFFFF6600), size: 28),
                    ),
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        b.businessName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF1A1918),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 14),
                        const SizedBox(width: 2),
                        Text(
                          b.averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Color(0xFF1A1918),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Category & Owner
                Text(
                  '${b.categoryName ?? "Sanatan Shop"} • ${b.ownerName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF5F5C58),
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 10),

                // Actions Button Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // View details button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        context.push('/business-detail/${b.businessId}');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6600).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'View',
                          style: TextStyle(
                            color: Color(0xFFFF6600),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Phone launcher
                    IconButton(
                      icon: const Icon(Icons.call_rounded, color: Color(0xFF5F5C58), size: 16),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        launchUrl(Uri.parse('tel:${b.phoneCode}${b.phoneNumber}'));
                      },
                    ),

                    // Directions launcher
                    IconButton(
                      icon: const Icon(Icons.directions_rounded, color: Color(0xFF5F5C58), size: 16),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        launchUrl(Uri.parse(
                            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(b.address)}'));
                      },
                    ),

                    // Favorite toggle
                    IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFav ? const Color(0xFFE1251B) : const Color(0xFF5F5C58),
                        size: 16,
                      ),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        ref.read(favoritesProvider.notifier).toggleFavorite(b.businessId);
                      },
                    ),

                    // Share
                    IconButton(
                      icon: const Icon(Icons.share_rounded, color: Color(0xFF5F5C58), size: 16),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Clipboard.setData(ClipboardData(
                          text: '${b.businessName} - Address: ${b.address}, Phone: ${b.phoneCode}${b.phoneNumber}',
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Business details copied to clipboard to share!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
