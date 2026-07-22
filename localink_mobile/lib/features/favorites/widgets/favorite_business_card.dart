import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../business/data/models/business_models.dart';
import '../../../../core/network/dio_client.dart';

class FavoriteBusinessCard extends StatefulWidget {
  final BusinessDto business;
  final VoidCallback onRemove;

  const FavoriteBusinessCard({
    super.key,
    required this.business,
    required this.onRemove,
  });

  @override
  State<FavoriteBusinessCard> createState() => _FavoriteBusinessCardState();
}

class _FavoriteBusinessCardState extends State<FavoriteBusinessCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: () => context.push('/business-detail/${widget.business.businessId}'),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F8F6),
            border: Border.all(color: const Color(0xFFEAE8E3)),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                // Image
                SizedBox(
                  width: 110,
                  height: 110,
                  child: widget.business.photos.isNotEmpty
                      ? Image.network(
                          '${Uri.parse(DioClient().dio.options.baseUrl).origin}${widget.business.photos.first}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, st) => Container(
                            color: const Color(0xFFF0EFEA),
                            child: const Icon(Icons.storefront_rounded, color: Color(0xFFFF6600), size: 30),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFF0EFEA),
                          child: const Icon(Icons.storefront_rounded, color: Color(0xFFFF6600), size: 30),
                        ),
                ),

                // Details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.business.businessName,
                          style: const TextStyle(
                            color: Color(0xFF1A1918),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.business.categoryName != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            widget.business.categoryName!,
                            style: const TextStyle(
                              color: Color(0xFFFF6600),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          widget.business.description,
                          style: const TextStyle(
                            color: Color(0xFF5F5C58),
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFFF6600), size: 14),
                            const SizedBox(width: 3),
                            Text(
                              widget.business.averageRating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Color(0xFF1A1918),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: Color(0xFFFF6600), size: 12),
                                const SizedBox(width: 2),
                                Text(
                                  widget.business.city,
                                  style: const TextStyle(
                                    color: Color(0xFF9F9B96),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Remove button
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 22),
                    onPressed: widget.onRemove,
                    tooltip: 'Remove from Favorites',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
