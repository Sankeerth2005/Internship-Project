import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/network/app_error_formatter.dart';

/// Admin categories grid — extracted from [AdminDashboardScreen].
class AdminCategoriesTab extends StatelessWidget {
  const AdminCategoriesTab({super.key});

  static IconData iconForCategory(String name) {
    final iconMap = <String, IconData>{
      'restaurant': Icons.restaurant,
      'food': Icons.restaurant,
      'cafe': Icons.local_cafe,
      'health': Icons.health_and_safety,
      'wellness': Icons.spa,
      'beauty': Icons.spa,
      'service': Icons.build,
      'auto': Icons.directions_car,
      'car': Icons.directions_car,
      'shop': Icons.shopping_bag,
      'retail': Icons.shopping_bag,
      'business': Icons.business,
      'education': Icons.school,
      'travel': Icons.flight,
      'real estate': Icons.home,
      'legal': Icons.gavel,
      'it': Icons.computer,
      'tech': Icons.computer,
      'market': Icons.campaign,
      'entertainment': Icons.movie,
      'religious': Icons.temple_hindu,
      'finance': Icons.account_balance,
      'pet': Icons.pets,
      'security': Icons.security,
      'gym': Icons.fitness_center,
      'medical': Icons.medical_services,
    };
    final lowerName = name.toLowerCase();
    for (final key in iconMap.keys) {
      if (lowerName.contains(key)) return iconMap[key]!;
    }
    return Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Response<dynamic>>(
      future: DioClient().dio.get('categories'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF7A00)),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          final msg = snapshot.hasError
              ? AppErrorFormatter.format(snapshot.error)
              : 'Failed to load categories';
          return Center(
            child: Text(msg, style: const TextStyle(color: Colors.white54)),
          );
        }
        final data = snapshot.data!.data as List? ?? [];

        return GridView.builder(
          padding: const EdgeInsets.all(15),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
          ),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final cat = data[index];
            final name = cat['name'] ?? cat['categoryName'] ?? 'Category';
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    iconForCategory(name.toString()),
                    color: const Color(0xFFFF7A00),
                    size: 28,
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      name.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
