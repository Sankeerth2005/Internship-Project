import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/admin_business_dto.dart';
import '../../providers/admin_provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/signalr_service.dart';
import '../../../auth/providers/auth_state.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  String _selectedFilter = 'Pending'; // Pending, Approved, Rejected, All
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleApprove(AdminBusinessDto business) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Approve Business', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to approve "${business.name}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      
      // Show loading HUD
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFC8A97E)),
        ),
      );

      final success = await ref.read(adminBusinessesProvider.notifier).approveBusiness(business.id);
      
      if (mounted) {
        Navigator.pop(context); // Pop loading HUD
        if (success) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('"${business.name}" has been approved!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Failed to approve business. Please try again.'),
              backgroundColor: Color(0xFFFF4D4F),
            ),
          );
        }
      }
    }
  }

  Future<void> _handleReject(AdminBusinessDto business) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Reject Business', style: TextStyle(color: Colors.white)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Provide a reason for rejecting "${business.name}":',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter rejection reason (required)...',
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFC8A97E)),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Rejection reason is required';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4D4F),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      final reason = reasonController.text.trim();
      final messenger = ScaffoldMessenger.of(context);

      // Show loading HUD
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFC8A97E)),
        ),
      );

      final success = await ref
          .read(adminBusinessesProvider.notifier)
          .rejectBusiness(business.id, reason);

      if (mounted) {
        Navigator.pop(context); // Pop loading HUD
        if (success) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('"${business.name}" has been rejected.'),
              backgroundColor: const Color(0xFFFF4D4F),
            ),
          );
        } else {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Failed to reject business. Please try again.'),
              backgroundColor: Color(0xFFFF4D4F),
            ),
          );
        }
      }
    }
    reasonController.dispose();
  }

  Future<void> _handleExport() async {
    final status = _selectedFilter == 'All' ? 'Pending' : _selectedFilter;
    final baseUrl = DioClient().dio.options.baseUrl;
    final originUrl = Uri.parse(baseUrl).origin;
    final exportUrl = '$originUrl/api/v1/admin/export?status=$status';
    
    try {
      final messenger = ScaffoldMessenger.of(context);
      final launched = await launchUrl(Uri.parse(exportUrl), mode: LaunchMode.externalApplication);
      if (!launched) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not launch export download link.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessesAsync = ref.watch(adminBusinessesProvider);
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vocal for Sanatan',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Admin Control Panel',
              style: TextStyle(color: Color(0xFFC8A97E), fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Color(0xFFC8A97E)),
            tooltip: 'Export Excel Report',
            onPressed: _handleExport,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Logout',
            onPressed: () {
              if (authState is AuthAuthenticated) {
                SignalRService().disconnect(authState.userId);
              }
              ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs row
          businessesAsync.when(
            data: (list) {
              final pendingCount = list.where((b) => b.status.toLowerCase() == 'pending').length;
              final approvedCount = list.where((b) => b.status.toLowerCase() == 'approved').length;
              final rejectedCount = list.where((b) => b.status.toLowerCase() == 'rejected').length;
              final totalCount = list.length;

              return Container(
                color: const Color(0xFF1E1E1E),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Pending', pendingCount),
                      const SizedBox(width: 8),
                      _buildFilterChip('Approved', approvedCount),
                      const SizedBox(width: 8),
                      _buildFilterChip('Rejected', rejectedCount),
                      const SizedBox(width: 8),
                      _buildFilterChip('All', totalCount),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SizedBox(height: 50),
            error: (err, stack) => const SizedBox(height: 50),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search business name, category, location...',
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFC8A97E), size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
            ),
          ),

          // Businesses List
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFFC8A97E),
              onRefresh: () async {
                ref.invalidate(adminBusinessesProvider);
              },
              child: businessesAsync.when(
                data: (list) {
                  // Filter list by Tab Selection
                  var filtered = list;
                  if (_selectedFilter != 'All') {
                    filtered = list.where((b) => b.status.toLowerCase() == _selectedFilter.toLowerCase()).toList();
                  }

                  // Filter by Search Query
                  if (_searchQuery.isNotEmpty) {
                    filtered = filtered.where((b) {
                      return b.name.toLowerCase().contains(_searchQuery) ||
                          b.category.toLowerCase().contains(_searchQuery) ||
                          (b.address?.toLowerCase().contains(_searchQuery) ?? false);
                    }).toList();
                  }

                  if (filtered.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                        const Center(
                          child: Column(
                            children: [
                              Icon(Icons.storefront, color: Colors.white24, size: 60),
                              SizedBox(height: 10),
                              Text(
                                'No businesses found',
                                style: TextStyle(color: Colors.white38, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _buildBusinessCard(filtered[index]);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFFC8A97E)),
                ),
                error: (err, st) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Failed to load businesses: $err',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC8A97E) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black26 : Colors.black45,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.black87 : Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessCard(AdminBusinessDto business) {
    Color badgeColor = Colors.amber;
    if (business.status.toLowerCase() == 'approved') {
      badgeColor = Colors.green;
    } else if (business.status.toLowerCase() == 'rejected') {
      badgeColor = Colors.redAccent;
    }

    final isPending = business.status.toLowerCase() == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  business.name,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  business.status,
                  style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Category
          Text(
            business.category,
            style: const TextStyle(color: Color(0xFFC8A97E), fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          // Description
          Text(
            business.description,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10),
          const SizedBox(height: 10),
          // Contact Information
          if (business.phone != null && business.phone!.isNotEmpty)
            _buildContactRow(Icons.phone, business.phone!),
          if (business.email != null && business.email!.isNotEmpty)
            _buildContactRow(Icons.email, business.email!),
          if (business.address != null && business.address!.isNotEmpty)
            _buildContactRow(Icons.location_on, business.address!),

          // Rejection Comments
          if (business.rejectionComment != null && business.rejectionComment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rejection Reason:',
                    style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    business.rejectionComment!,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],

          // Approval Action Buttons (Only for Pending)
          if (isPending) ...[
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF4D4F),
                      side: const BorderSide(color: Color(0xFFFF4D4F)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _handleReject(business),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _handleApprove(business),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFC8A97E), size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
