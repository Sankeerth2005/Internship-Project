import 'package:flutter/material.dart';
import '../../../../core/network/dio_client.dart';
import '../data/models/business_models.dart';

class BusinessReviewCard extends StatelessWidget {
  final BusinessReviewDto review;

  const BusinessReviewCard({
    super.key,
    required this.review,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F8F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAE8E3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                review.userName,
                style: const TextStyle(
                  color: Color(0xFF1A1918),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    Icons.star_rounded,
                    color: index < review.rating ? const Color(0xFFFF6600) : const Color(0xFFEAE8E3),
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.comment,
            style: const TextStyle(
              color: Color(0xFF5F5C58),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          if (review.imageUrl != null && review.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                review.imageUrl!.startsWith('http')
                    ? review.imageUrl!
                    : '${DioClient().dio.options.baseUrl.replaceAll('/api/v1/', '')}${review.imageUrl}',
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EFEA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.broken_image_rounded,
                      color: Color(0xFF9F9B96),
                      size: 24,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
