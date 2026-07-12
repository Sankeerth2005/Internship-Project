import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/business_provider.dart';
import '../../data/models/business_models.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/providers/auth_state.dart';
import '../../../../core/network/signalr_service.dart';
import '../../../../core/network/dio_client.dart';

class BusinessDashboardScreen extends ConsumerWidget {
  const BusinessDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myBusinessesAsync = ref.watch(myBusinessesProvider);
    final authState = ref.watch(authProvider);

    if (authState is AuthAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SignalRService().connect(authState.userId, authState.userType, context);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: const Text(
          'Business Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Color(0xFFC8A97E)),
            onPressed: () => context.push('/owner-profile'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFC8A97E)),
            onPressed: () => ref.read(myBusinessesProvider.notifier).refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () {
              if (authState is AuthAuthenticated) {
                SignalRService().disconnect(authState.userId);
              }
              ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: myBusinessesAsync.when(
        data: (businesses) {
          if (businesses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFC8A97E).withValues(alpha: 0.2)),
                      ),
                      child: const Icon(Icons.storefront, color: Color(0xFFC8A97E), size: 50),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Businesses Registered Yet',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Register your business to start displaying it to local users.',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC8A97E),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Register Business', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => context.push('/register-business'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: businesses.length,
            itemBuilder: (context, index) {
              return _buildDashboardCard(context, businesses[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFC8A97E))),
        error: (err, st) => Center(
          child: Text(
            'Error: $err',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFC8A97E),
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
        onPressed: () => context.push('/register-business'),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, BusinessDto business) {
    // Determine status color
    final isApproved = business.status?.toLowerCase() == 'approved';
    final statusColor = isApproved ? Colors.green : Colors.amber;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Business Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFC8A97E).withValues(alpha: 0.1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: business.photos.isNotEmpty
                  ? Image.network(
                      '${Uri.parse(DioClient().dio.options.baseUrl).origin}${business.photos.first}',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.store,
                        color: Color(0xFFC8A97E),
                        size: 24,
                      ),
                    )
                  : const Icon(
                      Icons.store,
                      color: Color(0xFFC8A97E),
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(width: 15),

          // Details
          Expanded(
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
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 5),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        business.status ?? 'Pending',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  business.description,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFFC8A97E), size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${business.address}, ${business.city}',
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View'),
                      onPressed: () => context.push('/business-detail/${business.businessId}'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC8A97E),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                      onPressed: () => context.push('/register-business', extra: business),
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
