import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/optimized_network_image.dart';

class AiFeedCard extends StatefulWidget {
  final Map<String, dynamic> item;

  const AiFeedCard({
    super.key,
    required this.item,
  });

  @override
  State<AiFeedCard> createState() => _AiFeedCardState();
}

class _AiFeedCardState extends State<AiFeedCard> {
  double _scale = 1.0;

  String _locationLabel() {
    final city = (widget.item['city'] ?? '').toString();
    final rawDistance = widget.item['distance'];
    final distance = rawDistance is num ? rawDistance.toDouble() : null;
    if (distance != null) {
      final distText = distance < 0.05
          ? 'Nearby'
          : distance < 1
              ? '${(distance * 1000).round()} m'
              : '${distance.toStringAsFixed(1)} km';
      return city.isNotEmpty ? '$city · $distText' : distText;
    }
    return city.isNotEmpty ? city : 'Near you';
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> photos = widget.item['photos'] ?? [];
    final photoUrl = photos.isNotEmpty
        ? '${DioClient.backendOrigin}${photos.first}'
        : null;
    final reason = (widget.item['reason'] ?? '').toString().trim();

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: () => context.push('/business-detail/${widget.item['businessId']}'),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F8F6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEAE8E3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (photoUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: OptimizedNetworkImage.business(
                    imageUrl: photoUrl,
                    height: 140,
                    width: double.infinity,
                    iconSize: 40,
                  ),
                )
              else
                Container(
                  height: 140,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0EFEA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.storefront_rounded,
                      color: Color(0xFFFF6600),
                      size: 40,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item['businessName'] ?? '',
                      style: const TextStyle(
                        color: Color(0xFF1A1918),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (reason.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        reason,
                        style: const TextStyle(
                          color: Color(0xFFFF6600),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      widget.item['description'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF5F5C58),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFFFF6600), size: 12),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _locationLabel(),
                            style: const TextStyle(
                              color: Color(0xFF9F9B96),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6600).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${widget.item['categoryName']} • ${widget.item['subcategoryName']}',
                            style: const TextStyle(
                              color: Color(0xFFFF6600),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
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
