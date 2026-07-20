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
      backgroundColor: const Color(0xFF080706),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141210),
        elevation: 0,
        centerTitle: false,
        title: const Row(
          children: [
            Icon(Icons.storefront_rounded, color: Color(0xFFFF7A00), size: 24),
            SizedBox(width: 10),
            Text(
              'Business Owner Hub',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_rounded, color: Color(0xFFFF7A00)),
            onPressed: () => context.push('/owner-profile'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFFFF7A00)),
            onPressed: () => ref.read(myBusinessesProvider.notifier).refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFFF3333)),
            onPressed: () {
              if (authState is AuthAuthenticated) {
                SignalRService().disconnect(authState.userId);
              }
              ref.read(authProvider.notifier).logout();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withValues(alpha: 0.05),
            height: 1,
          ),
        ),
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
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141210),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFF7A00).withValues(alpha: 0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF7A00).withValues(alpha: 0.15),
                            blurRadius: 20,
                          )
                        ],
                      ),
                      child: const Icon(Icons.add_business_rounded, color: Color(0xFFFF7A00), size: 50),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No Businesses Registered Yet',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Register your store or service to connect with thousands of local users.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: 220,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B00),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          elevation: 4,
                        ),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Register Store', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        onPressed: () => context.push('/register-business'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final totalCount = businesses.length;
          final approvedCount = businesses.where((b) => b.status?.toLowerCase() == 'approved').length;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Top Owner Summary Banner Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1C1917), Color(0xFF100F0E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFF7A00).withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Store Performance Overview',
                                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Manage listings, hours & photos from one hub.',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      _buildStatBadge('Total', totalCount.toString(), const Color(0xFFFF7A00)),
                                      const SizedBox(width: 12),
                                      _buildStatBadge('Live', approvedCount.toString(), const Color(0xFF4CAF50)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF7A00).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.analytics_rounded, color: Color(0xFFFF7A00), size: 36),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Row(
                        children: [
                          Icon(Icons.storefront_rounded, color: Color(0xFFFF7A00), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Your Registered Businesses',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Business Cards List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildDashboardCard(context, ref, businesses[index]);
                    },
                    childCount: businesses.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A00))),
        error: (err, stack) => Center(
          child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent)),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: FloatingActionButton.extended(
          backgroundColor: const Color(0xFFFF6B00),
          foregroundColor: Colors.white,
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Add Business', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () => context.push('/register-business'),
        ),
      ),
    );
  }

  Widget _buildStatBadge(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Text(count, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, WidgetRef ref, BusinessDto business) {
    final isApproved = business.status?.toLowerCase() == 'approved';
    Color statusColor = isApproved ? const Color(0xFF4CAF50) : Colors.amber;
    var statusText = business.status ?? 'Pending';

    if (business.status?.toLowerCase() == 'deletionrequested') {
      statusColor = const Color(0xFFFF3333);
      statusText = 'Deletion Pending';
    } else if (business.isTemporarilyClosed) {
      statusColor = const Color(0xFFFF3333);
      statusText = 'Temp Closed';
    } else if (business.temporaryClosureStatus?.toLowerCase() == 'pending') {
      statusColor = Colors.orangeAccent;
      statusText = 'Closure Pending';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141210),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFF7A00).withValues(alpha: 0.2)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: business.photos.isNotEmpty
                      ? Image.network(
                          '${Uri.parse(DioClient().dio.options.baseUrl).origin}${business.photos.first}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.storefront_rounded,
                            color: Color(0xFFFF7A00),
                            size: 28,
                          ),
                        )
                      : const Icon(
                          Icons.storefront_rounded,
                          color: Color(0xFFFF7A00),
                          size: 28,
                        ),
                ),
              ),
              const SizedBox(width: 14),
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
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      business.city.isNotEmpty ? '${business.city}, ${business.state}' : 'Location set',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),
          // Action Buttons Toolbar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                icon: Icons.edit_note_rounded,
                label: 'Edit Details',
                onTap: () => context.push('/edit-business/${business.businessId}', extra: business),
              ),
              _buildActionButton(
                icon: Icons.analytics_outlined,
                label: 'Analytics',
                onTap: () => context.push('/analytics/${business.businessId}'),
              ),
              _buildActionButton(
                icon: Icons.photo_library_outlined,
                label: 'Photos',
                onTap: () => context.push('/manage-photos/${business.businessId}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFF7A00), size: 16),
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
}
