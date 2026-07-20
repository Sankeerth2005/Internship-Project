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

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/welcome');
        }
      },
      child: Scaffold(
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
                // ─── 1. HERO PROMOTIONAL BANNER FOR BUSINESS OWNER ───
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF7A00), Color(0xFFFF5100)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF7A00).withValues(alpha: 0.25),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Expanding your community',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Register and showcase your business to thousands of local customers nearby.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    fontSize: 11.5,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                ElevatedButton.icon(
                                  onPressed: () => context.push('/register-business'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFFFF6B00),
                                    elevation: 4,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: const Text(
                                    'List your store',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ─── 2. STORE PERFORMANCE OVERVIEW CARD ───
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1C1917), Color(0xFF100F0E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFF7A00).withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Store Performance Overview',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Manage listings, operating hours & performance stats.',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  _buildStatBadge('Total Stores', totalCount.toString(), const Color(0xFFFF7A00)),
                                  const SizedBox(width: 12),
                                  _buildStatBadge('Live Approved', approvedCount.toString(), const Color(0xFF4CAF50)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
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
                        const SizedBox(height: 8),
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

                const SliverToBoxAdapter(child: SizedBox(height: 50)),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A00))),
          error: (err, stack) => Center(
            child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent)),
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(count, style: TextStyle(color: color, fontSize: 13.5, fontWeight: FontWeight.w900)),
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
          const SizedBox(height: 14),
          // Row 1 of Action Buttons: View Details, Edit Details, Analytics
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.visibility_rounded,
                  label: 'View Details',
                  onTap: () => context.push('/business-detail/${business.businessId}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.edit_note_rounded,
                  label: 'Edit Details',
                  onTap: () => context.push('/edit-business/${business.businessId}', extra: business),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.analytics_outlined,
                  label: 'Analytics',
                  onTap: () => context.push('/analytics/${business.businessId}', extra: business),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Row 2 of Action Buttons: Temp Closure & Permanent Delete
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: business.isTemporarilyClosed ? Icons.play_circle_fill_rounded : Icons.pause_circle_outline_rounded,
                  label: business.isTemporarilyClosed ? 'Reopen Store' : 'Temp Closure',
                  accentColor: Colors.amber,
                  onTap: () => _showTemporaryClosureDialog(context, ref, business),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete Store',
                  accentColor: const Color(0xFFFF3333),
                  onTap: () => _showDeletionDialog(context, ref, business),
                ),
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
    Color? accentColor,
  }) {
    final color = accentColor ?? const Color(0xFFFF7A00);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: accentColor != null ? color : Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTemporaryClosureDialog(BuildContext context, WidgetRef ref, BusinessDto business) {
    if (business.isTemporarilyClosed) {
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: const Color(0xFF141210),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Reopen Business', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(
            'Your business "${business.businessName}" is currently marked as temporarily closed. Would you like to reopen it now?',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7A00), foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                final success = await ref.read(myBusinessesProvider.notifier).cancelTemporaryClosure(business.businessId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(success ? 'Business reopened successfully.' : 'Failed to reopen business.')),
                  );
                }
              },
              child: const Text('Reopen Store', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    final reasonController = TextEditingController();
    int closureDays = 7;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF141210),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.pause_circle_outline_rounded, color: Colors.amber, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Temporary Closure (${business.businessName})',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reason for temporary closure is mandatory.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Enter reason (e.g. renovation, vacation)...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF1C1917),
                    errorText: errorMessage,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF7A00)),
                    ),
                  ),
                  onChanged: (val) {
                    if (val.trim().isNotEmpty && errorMessage != null) {
                      setDialogState(() {
                        errorMessage = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                const Text('Closure Duration (Days):', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1917),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: closureDays,
                      dropdownColor: const Color(0xFF1C1917),
                      isExpanded: true,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      items: const [
                        DropdownMenuItem(value: 3, child: Text('3 Days')),
                        DropdownMenuItem(value: 7, child: Text('7 Days (1 Week)')),
                        DropdownMenuItem(value: 14, child: Text('14 Days (2 Weeks)')),
                        DropdownMenuItem(value: 30, child: Text('30 Days (1 Month)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            closureDays = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                onPressed: () async {
                  final reason = reasonController.text.trim();
                  if (reason.isEmpty) {
                    setDialogState(() {
                      errorMessage = 'Reason is mandatory for temporary closure';
                    });
                    return;
                  }
                  Navigator.pop(dialogCtx);
                  final success = await ref.read(myBusinessesProvider.notifier).requestTemporaryClosure(
                    business.businessId,
                    reason,
                    closureDays,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Temporary closure submitted successfully.' : 'Failed to submit closure request.'),
                      ),
                    );
                  }
                },
                child: const Text('Submit Closure', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeletionDialog(BuildContext context, WidgetRef ref, BusinessDto business) {
    final reasonController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF141210),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.delete_forever_rounded, color: Color(0xFFFF3333), size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Permanent Store Deletion',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to request deletion for "${business.businessName}"? A mandatory reason is required for admin review.',
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Enter mandatory reason for deletion...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF1C1917),
                    errorText: errorMessage,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF3333)),
                    ),
                  ),
                  onChanged: (val) {
                    if (val.trim().isNotEmpty && errorMessage != null) {
                      setDialogState(() {
                        errorMessage = null;
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF3333), foregroundColor: Colors.white),
                onPressed: () async {
                  final reason = reasonController.text.trim();
                  if (reason.isEmpty) {
                    setDialogState(() {
                      errorMessage = 'Reason is mandatory for deletion request';
                    });
                    return;
                  }
                  Navigator.pop(dialogCtx);
                  final success = await ref.read(myBusinessesProvider.notifier).requestDeletion(
                    business.businessId,
                    reason,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Deletion request submitted to admin successfully.' : 'Failed to submit deletion request.'),
                      ),
                    );
                  }
                },
                child: const Text('Request Deletion', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }
}
