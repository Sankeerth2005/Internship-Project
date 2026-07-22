import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../auth/providers/auth_provider.dart';
import '../../data/models/admin_business_dto.dart';
import '../../providers/admin_provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/signalr_service.dart';
import '../../../auth/providers/auth_state.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../shared/presentation/widgets/app_feedback.dart';
import '../../../../core/network/app_error_formatter.dart';

// Import modular widgets
import '../widgets/kpi_card.dart';
import '../widgets/platform_health_widget.dart';
import '../widgets/ai_insights_panel.dart';
import '../widgets/business_approval_sheet.dart';
import '../widgets/analytics_charts.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  String _selectedFilter = 'Pending'; // Pending, Approved, Rejected, All
  final _searchController = TextEditingController();
  final _userSearchController = TextEditingController();
  String _searchQuery = '';
  String _userSearchQuery = '';
  int _currentTab = 0; // 0 = Dashboard & Businesses, 1 = Categories, 2 = Reports/Analytics, 3 = Users, 4 = Settings

  @override
  void dispose() {
    _searchController.dispose();
    _userSearchController.dispose();
    super.dispose();
  }

  Future<void> _handleApproveDeletion(AdminBusinessDto business) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Approve Permanent Deletion', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to PERMANENTLY DELETE "${business.name}"? This will delete it completely from the database and cannot be undone.\n\nReason: "${business.rejectionComment ?? "No reason specified"}"',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve & Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A00))),
      );

      try {
        final success = await ref.read(adminBusinessesProvider.notifier).approvePermanentDeletion(business.id);

        if (mounted) {
          Navigator.pop(context); // Pop loading
          if (success) {
            AppFeedback.showSuccess(context, '"${business.name}" has been permanently deleted.');
          } else {
            AppFeedback.showError(context, 'Failed to delete business. Please try again.');
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Pop loading
          AppFeedback.showError(context, AppErrorFormatter.format(e));
        }
      }
    }
  }

  Future<void> _handleRejectDeletion(AdminBusinessDto business) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Reject Deletion Request', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to REJECT the deletion request for "${business.name}"? The business status will be restored to Approved.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7A00),
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject Request & Keep Business'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A00))),
      );

      try {
        final success = await ref.read(adminBusinessesProvider.notifier).approveBusiness(business.id);

        if (mounted) {
          Navigator.pop(context); // Pop loading
          if (success) {
            AppFeedback.showSuccess(context, 'Deletion request for "${business.name}" has been rejected.');
          } else {
            AppFeedback.showError(context, 'Failed to reject deletion request. Please try again.');
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Pop loading
          AppFeedback.showError(context, AppErrorFormatter.format(e));
        }
      }
    }
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
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF7A00)),
        ),
      );

      try {
        final success = await ref.read(adminBusinessesProvider.notifier).approveBusiness(business.id);
        
        if (mounted) {
          Navigator.pop(context); // Pop loading HUD
          if (success) {
            AppFeedback.showSuccess(context, '"${business.name}" has been approved!');
          } else {
            AppFeedback.showError(context, 'Failed to approve business. Please try again.');
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Pop loading HUD
          AppFeedback.showError(context, AppErrorFormatter.format(e));
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
                    borderSide: const BorderSide(color: Color(0xFFFF7A00)),
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

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF7A00)),
        ),
      );

      try {
        final success = await ref
            .read(adminBusinessesProvider.notifier)
            .rejectBusiness(business.id, reason);

        if (mounted) {
          Navigator.pop(context); // Pop loading HUD
          if (success) {
            AppFeedback.showSuccess(context, '"${business.name}" has been rejected.');
          } else {
            AppFeedback.showError(context, 'Failed to reject business. Please try again.');
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Pop loading HUD
          AppFeedback.showError(context, AppErrorFormatter.format(e));
        }
      }
    }
    reasonController.dispose();
  }

  Future<void> _handleApproveClosure(AdminBusinessDto business) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Approve Closure Request', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to approve temporary closure for "${business.name}" for ${business.temporaryClosureDays ?? 0} days?\n\nReason: "${business.temporaryClosureReason ?? "No reason specified"}"',
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
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF7A00)),
        ),
      );

      try {
        final success = await ref.read(adminBusinessesProvider.notifier).approveTemporaryClosure(business.id);
        
        if (mounted) {
          Navigator.pop(context); // Pop loading
          if (success) {
            AppFeedback.showSuccess(context, 'Temporary closure approved for "${business.name}"!');
          } else {
            AppFeedback.showError(context, 'Failed to approve closure. Please try again.');
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Pop loading
          AppFeedback.showError(context, AppErrorFormatter.format(e));
        }
      }
    }
  }

  Future<void> _handleRejectClosure(AdminBusinessDto business) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Reject Closure Request', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to reject the temporary closure request for "${business.name}"?',
          style: const TextStyle(color: Colors.white70),
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
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF7A00)),
        ),
      );

      try {
        final success = await ref.read(adminBusinessesProvider.notifier).rejectTemporaryClosure(business.id);
        
        if (mounted) {
          Navigator.pop(context); // Pop loading
          if (success) {
            AppFeedback.showSuccess(context, 'Temporary closure request rejected for "${business.name}".');
          } else {
            AppFeedback.showError(context, 'Failed to reject closure. Please try again.');
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Pop loading
          AppFeedback.showError(context, AppErrorFormatter.format(e));
        }
      }
    }
  }

  Future<void> _handleExport() async {
    final statusChoice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select Report Type to Export',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.list, color: Color(0xFFFF7A00)),
              title: const Text('All Businesses', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, 'All'),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline, color: Colors.green),
              title: const Text('Approved Businesses Only', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, 'Approved'),
            ),
            ListTile(
              leading: const Icon(Icons.pending_actions, color: Colors.amber),
              title: const Text('Pending Businesses Only', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, 'Pending'),
            ),
            ListTile(
              leading: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
              title: const Text('Rejected Businesses Only', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, 'Rejected'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (statusChoice == null) return;

    final token = await SecureStorageService.getToken();
    final baseUrl = DioClient().dio.options.baseUrl;
    final originUrl = Uri.parse(baseUrl).origin;
    final exportUrl = '$originUrl/api/v1/admin/export?status=$statusChoice&access_token=$token';
    
    try {
      final launched = await launchUrl(Uri.parse(exportUrl), mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        AppFeedback.showError(context, 'Could not launch export download link.');
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, AppErrorFormatter.format(e));
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
        backgroundColor: const Color(0xFF0C0C0C),
        body: Column(
          children: [
            // Custom Saffron Sunrise Temple skyline header
            Container(
              height: 110 + MediaQuery.of(context).padding.top,
              width: double.infinity,
              child: CustomPaint(
                painter: TempleHeaderPainter(),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 10 + MediaQuery.of(context).padding.top,
                    bottom: 10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        child: CustomPaint(
                          painter: EmblemPainter(),
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Vocal for Sanatan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Enterprise Command Center',
                              style: TextStyle(
                                color: Color(0xFFFF7A00),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.download, color: Color(0xFFFF7A00), size: 22),
                            tooltip: 'Export Excel Report',
                            onPressed: _handleExport,
                          ),
                          IconButton(
                            icon: const Icon(Icons.map_outlined, color: Color(0xFFFF7A00), size: 22),
                            tooltip: 'Operational Heatmap',
                            onPressed: () => context.push('/admin-heatmap'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
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
                    ],
                  ),
                ),
              ),
            ),
            // Tab View Body Panel
            Expanded(
              child: _buildTabContent(businessesAsync),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1)),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentTab,
            onTap: (index) {
              setState(() {
                _currentTab = index;
              });
            },
            backgroundColor: Colors.transparent,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFFFF7A00),
            unselectedItemColor: Colors.white38,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.storefront_outlined),
                label: 'Listings',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.grid_view_outlined),
                label: 'Categories',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined),
                label: 'Analytics',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                label: 'Users',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(AsyncValue<List<AdminBusinessDto>> businessesAsync) {
    switch (_currentTab) {
      case 0:
        return _buildCommandCenterTab(businessesAsync);
      case 1:
        return _buildBusinessesTab(businessesAsync);
      case 2:
        return _buildCategoriesTab();
      case 3:
        return _buildAnalyticsTab(businessesAsync);
      case 4:
        return _buildUsersTab();
      case 5:
        return _buildSettingsTab();
      default:
        return _buildCommandCenterTab(businessesAsync);
    }
  }

  Widget _buildCommandCenterTab(AsyncValue<List<AdminBusinessDto>> businessesAsync) {
    return businessesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A00))),
      error: (err, st) => Center(child: Text('Error loading dashboard: $err', style: const TextStyle(color: Colors.redAccent))),
      data: (list) {
        final pendingCount = list.where((b) => b.status.toLowerCase() == 'pending').length;
        final approvedCount = list.where((b) => b.status.toLowerCase() == 'approved').length;
        final deletionPendingCount = list.where((b) => b.status.toLowerCase() == 'deletionrequested').length;
        final totalCount = list.length;

        // Current Date
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final now = DateTime.now();
        final dateStr = '${now.day} ${months[now.month - 1]} ${now.year}';

        return RefreshIndicator(
          color: const Color(0xFFFF7A00),
          onRefresh: () async {
            ref.invalidate(adminBusinessesProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome banner section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome, Administrator',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white54),
                      onPressed: () => ref.invalidate(adminBusinessesProvider),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // KPI Cards Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    KpiCard(
                      title: 'Total Businesses',
                      value: totalCount.toString(),
                      icon: Icons.storefront_outlined,
                      accentColor: Colors.blueAccent,
                    ),
                    KpiCard(
                      title: 'Pending Approvals',
                      value: pendingCount.toString(),
                      icon: Icons.access_time_filled_outlined,
                      accentColor: Colors.amber,
                    ),
                    KpiCard(
                      title: 'Approved Listings',
                      value: approvedCount.toString(),
                      icon: Icons.check_circle_outline_rounded,
                      accentColor: Colors.green,
                    ),
                    KpiCard(
                      title: 'Deletion Requests',
                      value: deletionPendingCount.toString(),
                      icon: Icons.delete_outline_rounded,
                      accentColor: Colors.redAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Health beacons card
                const PlatformHealthWidget(),
                const SizedBox(height: 20),
                // AI Insights
                AiInsightsPanel(businesses: list),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBusinessesTab(AsyncValue<List<AdminBusinessDto>> businessesAsync) {
    return Column(
      children: [
        // Filter Tabs row
        businessesAsync.when(
          data: (list) {
            final pendingCount = list.where((b) => b.status.toLowerCase() == 'pending').length;
            final approvedCount = list.where((b) => b.status.toLowerCase() == 'approved').length;
            final rejectedCount = list.where((b) => b.status.toLowerCase() == 'rejected').length;
            final closurePendingCount = list.where((b) => b.isTemporaryClosurePending).length;
            final deletionPendingCount = list.where((b) => b.status.toLowerCase() == 'deletionrequested').length;
            final totalCount = list.length;

            return Container(
              color: const Color(0xFF161616),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Pending', pendingCount),
                    const SizedBox(width: 8),
                    _buildFilterChip('Closure Requests', closurePendingCount),
                    const SizedBox(width: 8),
                    _buildFilterChip('Deletion Requests', deletionPendingCount),
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
              prefixIcon: const Icon(Icons.search, color: Color(0xFFFF7A00), size: 20),
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
              fillColor: const Color(0xFF161616),
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
            color: const Color(0xFFFF7A00),
            onRefresh: () async {
              ref.invalidate(adminBusinessesProvider);
            },
            child: businessesAsync.when(
              data: (list) {
                var filtered = list;
                if (_selectedFilter == 'Closure Requests') {
                  filtered = list.where((b) => b.isTemporaryClosurePending).toList();
                } else if (_selectedFilter == 'Deletion Requests') {
                  filtered = list.where((b) => b.status.toLowerCase() == 'deletionrequested').toList();
                } else if (_selectedFilter != 'All') {
                  filtered = list.where((b) => b.status.toLowerCase() == _selectedFilter.toLowerCase()).toList();
                }

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
                            Icon(Icons.storefront_outlined, color: Colors.white24, size: 60),
                            SizedBox(height: 10),
                            Text(
                              'No listings found',
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
                child: CircularProgressIndicator(color: Color(0xFFFF7A00)),
              ),
              error: (err, st) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Failed to load listings: $err',
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
    );
  }

  Widget _buildCategoriesTab() {
    return FutureBuilder(
      future: DioClient().dio.get('categories'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A00)));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('Failed to load categories', style: TextStyle(color: Colors.white54)));
        }
        final data = snapshot.data!.data as List? ?? [];

        final iconMap = <String, IconData>{
          'restaurant': Icons.restaurant, 'food': Icons.restaurant, 'cafe': Icons.local_cafe,
          'health': Icons.health_and_safety, 'wellness': Icons.spa, 'beauty': Icons.spa,
          'service': Icons.build, 'auto': Icons.directions_car, 'car': Icons.directions_car,
          'shop': Icons.shopping_bag, 'retail': Icons.shopping_bag, 'store': Icons.store,
          'education': Icons.school, 'travel': Icons.flight, 'real estate': Icons.home,
          'legal': Icons.gavel, 'it': Icons.computer, 'tech': Icons.computer,
          'market': Icons.campaign, 'entertainment': Icons.movie, 'religious': Icons.temple_hindu,
          'finance': Icons.account_balance, 'pet': Icons.pets, 'security': Icons.security,
          'gym': Icons.fitness_center, 'medical': Icons.medical_services,
        };

        IconData getIconForCategory(String name) {
          final lowerName = name.toLowerCase();
          for (final key in iconMap.keys) {
            if (lowerName.contains(key)) return iconMap[key]!;
          }
          return Icons.category_outlined;
        }

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
                  Icon(getIconForCategory(name), color: const Color(0xFFFF7A00), size: 28),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
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

  Widget _buildAnalyticsTab(AsyncValue<List<AdminBusinessDto>> businessesAsync) {
    final statsAsync = ref.watch(adminStatsProvider);
    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A00))),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white24, size: 48),
            const SizedBox(height: 12),
            Text(
              'Failed to load analytics: $err',
              style: const TextStyle(color: Colors.white38, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      data: (stats) {
        final totalClicks = stats['totalClicks']?.toString() ?? '0';
        final totalViews = stats['totalViews']?.toString() ?? '0';
        final totalReviews = stats['totalReviews']?.toString() ?? '0';
        final avgRating = stats['averageRating'] != null
            ? '${stats['averageRating']} ★'
            : '— ★';
        final totalUsers = stats['totalUsers']?.toString() ?? '0';
        final totalBusinesses = stats['totalBusinesses']?.toString() ?? '0';

        return RefreshIndicator(
          color: const Color(0xFFFF7A00),
          onRefresh: () => ref.refresh(adminStatsProvider.future),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Real-Time Charts',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                businessesAsync.when(
                  data: (bList) => BusinessStatusPieChart(businesses: bList),
                  loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
                  error: (e, s) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),
                EngagementBarChart(stats: stats),
                const SizedBox(height: 24),
                const Text(
                  'System Totals',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard('Total Clicks', totalClicks, Icons.ads_click, Colors.blueAccent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard('Business Views', totalViews, Icons.remove_red_eye, Colors.green),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard('Total Users', totalUsers, Icons.people, Colors.purpleAccent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard('Businesses', totalBusinesses, Icons.storefront, const Color(0xFFFF7A00)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161616),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Average Rating', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          Text(avgRating, style: const TextStyle(color: Color(0xFFFF7A00), fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(color: Colors.white10, height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Review Count', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          Text('$totalReviews reviews', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildExportOptionCard(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildExportOptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF7A00).withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: Color(0xFFFF7A00), size: 32),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Export Database Report', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('Download Microsoft Excel reports.', style: TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7A00),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: _handleExport,
            child: const Text('Export', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    final usersAsync = ref.watch(adminUsersProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _userSearchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search user by name or email...',
              hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Color(0xFFFF7A00), size: 20),
              suffixIcon: _userSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white70, size: 18),
                      onPressed: () {
                        _userSearchController.clear();
                        setState(() {
                          _userSearchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF161616),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) {
              setState(() {
                _userSearchQuery = val.trim().toLowerCase();
              });
            },
          ),
        ),
        Expanded(
          child: usersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A00))),
            error: (err, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, color: Colors.white24, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load users: $err',
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            data: (usersList) {
              var users = usersList as List? ?? [];
              if (_userSearchQuery.isNotEmpty) {
                users = users.where((u) {
                  final name = u['fullName']?.toString().toLowerCase() ?? '';
                  final email = u['email']?.toString().toLowerCase() ?? '';
                  return name.contains(_userSearchQuery) || email.contains(_userSearchQuery);
                }).toList();
              }

              if (users.isEmpty) {
                return const Center(
                  child: Text('No users found', style: TextStyle(color: Colors.white54)),
                );
              }

              return RefreshIndicator(
                color: const Color(0xFFFF7A00),
                onRefresh: () => ref.refresh(adminUsersProvider.future),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index] as Map<String, dynamic>;
                    final name = user['fullName']?.toString() ?? 'Unknown';
                    final email = user['email']?.toString() ?? '';
                    final accountType = user['accountType']?.toString() ?? 'client';
                    final phone = user['phoneNumber']?.toString();

                    String roleLabel = 'Regular User';
                    Color roleColor = Colors.blueAccent;
                    if (accountType.toLowerCase() == 'admin') {
                      roleLabel = 'Administrator';
                      roleColor = const Color(0xFFFF7A00);
                    } else if (accountType.toLowerCase() == 'businessowner') {
                      roleLabel = 'Business Owner';
                      roleColor = Colors.green;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161616),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFFFF7A00).withValues(alpha: 0.1),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(color: Color(0xFFFF7A00), fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
                                const SizedBox(height: 2),
                                Text(email, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                if (phone != null && phone.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(phone, style: const TextStyle(color: Colors.white24, fontSize: 10))
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: roleColor.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              roleLabel,
                              style: TextStyle(color: roleColor, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFFFF7A00),
                  foregroundColor: Colors.black,
                  child: Icon(Icons.admin_panel_settings_outlined),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Admin Account', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text('sankeerth559@gmail.com', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSettingsOptionTile('Operational Hub Connection', 'Connected', Icons.wifi_outlined, Colors.green),
          const SizedBox(height: 10),
          _buildSettingsOptionTile('System Version', 'v1.4.2-stable', Icons.info_outline, Colors.blue),
          const SizedBox(height: 10),
          _buildSettingsOptionTile('Maintenance Mode (future-ready)', 'Inactive', Icons.construction_outlined, Colors.amber),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                final authState = ref.read(authProvider);
                if (authState is AuthAuthenticated) {
                  SignalRService().disconnect(authState.userId);
                }
                ref.read(authProvider.notifier).logout();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsOptionTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
          Text(value, style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    
    IconData chipIcon = Icons.list;
    if (label == 'Pending') {
      chipIcon = Icons.access_time_outlined;
    } else if (label == 'Closure Requests') {
      chipIcon = Icons.timer_off_outlined;
    } else if (label == 'Approved') {
      chipIcon = Icons.check_circle_outline;
    } else if (label == 'Rejected') {
      chipIcon = Icons.cancel_outlined;
    }

    final activeColor = const Color(0xFFFF7A00);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : const Color(0xFF161616),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : Colors.white.withValues(alpha: 0.04),
          ),
        ),
        child: Row(
          children: [
            Icon(
              chipIcon,
              size: 14,
              color: isSelected ? Colors.white : activeColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black26 : Colors.black45,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
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
    Color statusColor = const Color(0xFFFF7A00);
    IconData statusIcon = Icons.check_circle_outline;
    String badgeText = business.status;

    if (business.status.toLowerCase() == 'deletionrequested') {
      statusColor = Colors.redAccent;
      statusIcon = Icons.delete_forever_outlined;
      badgeText = 'Deletion Request';
    } else if (business.isTemporaryClosurePending) {
      statusColor = Colors.orangeAccent;
      statusIcon = Icons.timer_off_outlined;
      badgeText = 'Closure Request';
    } else if (business.status.toLowerCase() == 'approved') {
      statusColor = const Color(0xFFFF7A00);
      statusIcon = Icons.check_circle_outline;
    } else if (business.status.toLowerCase() == 'rejected') {
      statusColor = Colors.redAccent;
      statusIcon = Icons.cancel_outlined;
    } else {
      statusColor = Colors.amber;
      statusIcon = Icons.access_time;
    }

    final isPending = business.status.toLowerCase() == 'pending' && !business.isTemporaryClosurePending;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => BusinessApprovalSheet(business: business),
              );
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFF7A00).withValues(alpha: 0.6), width: 1.5),
                    color: Colors.black26,
                  ),
                  child: Center(
                    child: Text(
                      business.name.isNotEmpty ? business.name[0].toUpperCase() : 'B',
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF7A00),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              business.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: statusColor.withValues(alpha: 0.8), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  badgeText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  statusIcon,
                                  color: statusColor,
                                  size: 11,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.spa_outlined,
                            color: Color(0xFFFF7A00),
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            business.category,
                            style: const TextStyle(
                              color: Color(0xFFFF7A00),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        business.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white10, height: 1),
                      const SizedBox(height: 12),
                      
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (business.phone != null && business.phone!.isNotEmpty) ...[
                              const Icon(Icons.phone, color: Color(0xFFFF7A00), size: 12),
                              const SizedBox(width: 6),
                              Text(
                                business.phone!,
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                            if (business.phone != null && business.phone!.isNotEmpty &&
                                business.email != null && business.email!.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text('|', style: TextStyle(color: Colors.white24)),
                              ),
                            ],
                            if (business.email != null && business.email!.isNotEmpty) ...[
                              const Icon(Icons.email, color: Color(0xFFFF7A00), size: 12),
                              const SizedBox(width: 6),
                              Text(
                                business.email!,
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      if (business.address != null && business.address!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: Color(0xFFFF7A00), size: 13),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                business.address!,
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          
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

          if (business.isTemporaryClosurePending) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer_off_outlined, color: Colors.orangeAccent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Temporary Closure Request (${business.temporaryClosureDays} Days)',
                          style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Reason: ${business.temporaryClosureReason ?? "No reason provided"}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],

          if (business.status.toLowerCase() == 'deletionrequested') ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.delete_forever_outlined, color: Colors.redAccent, size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Permanent Deletion Requested',
                          style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Reason: ${business.rejectionComment ?? "No reason provided"}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],

          if (business.status.toLowerCase() == 'deletionrequested') ...[
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF7A00),
                      side: const BorderSide(color: Color(0xFFFF7A00)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject Request', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _handleRejectDeletion(business),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.delete_forever, size: 16),
                    label: const Text('Approve & Delete', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _handleApproveDeletion(business),
                  ),
                ),
              ],
            ),
          ],

          if (isPending) ...[
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF4D4F),
                      side: const BorderSide(color: Color(0xFFFF4D4F)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _handleReject(business),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7A00),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _handleApprove(business),
                  ),
                ),
              ],
            ),
          ],

          if (business.isTemporaryClosurePending) ...[
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF4D4F),
                      side: const BorderSide(color: Color(0xFFFF4D4F)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject Request', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _handleRejectClosure(business),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve Closure', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _handleApproveClosure(business),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class EmblemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    final paint = Paint()
      ..color = const Color(0xFFFF7A00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, paint);

    for (int i = 0; i < 24; i++) {
      double angle = (i * 360 / 24) * 3.14159 / 180;
      Offset p1 = Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
      Offset p2 = Offset(center.dx + (radius + 3) * math.cos(angle), center.dy + (radius + 3) * math.sin(angle));
      canvas.drawLine(p1, p2, paint);
    }

    final flagPaint = Paint()
      ..color = const Color(0xFFFF7A00)
      ..style = PaintingStyle.fill;

    final flagPath = Path();
    double poleX = center.dx - 4;
    flagPath.moveTo(poleX, center.dy - radius + 4);
    flagPath.lineTo(poleX, center.dy + radius - 4);

    double clothTopY = center.dy - radius + 6;
    double clothBottomY = center.dy + 2;
    double tipX = center.dx + radius - 4;

    flagPath.moveTo(poleX, clothTopY);
    flagPath.lineTo(tipX, (clothTopY + clothBottomY) / 2);
    flagPath.lineTo(poleX, clothBottomY);
    flagPath.close();

    canvas.drawPath(flagPath, flagPaint);

    final poleLinePaint = Paint()
      ..color = const Color(0xFF0C0C0C)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(poleX, center.dy - radius + 4), Offset(poleX, center.dy + radius - 4), poleLinePaint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'ॐ',
        style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    double clothCenterX = poleX + ((tipX - poleX) * 0.33);
    double clothCenterY = (clothTopY + clothBottomY) / 2;

    textPainter.paint(
      canvas,
      Offset(clothCenterX - (textPainter.width / 2), clothCenterY - (textPainter.height / 2)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TempleHeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.65, -0.3),
        radius: 1.5,
        colors: [
          const Color(0xFFFF6600).withValues(alpha: 0.9),
          const Color(0xFFE65100).withValues(alpha: 0.8),
          const Color(0xFF0C0C0C),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final silPaint = Paint()
      ..color = const Color(0xFF0C0C0C)
      ..style = PaintingStyle.fill;

    final path = Path();
    double bottomY = size.height;
    double w = size.width;

    path.moveTo(0, bottomY);
    path.lineTo(0, bottomY - 10);
    path.quadraticBezierTo(w * 0.3, bottomY - 5, w * 0.5, bottomY - 8);
    path.quadraticBezierTo(w * 0.75, bottomY - 12, w, bottomY - 5);
    path.lineTo(w, bottomY);
    canvas.drawPath(path, silPaint);

    final pathLeft = Path();
    drawShikhara(pathLeft, w * 0.62, bottomY, w * 0.18, size.height * 0.5);
    canvas.drawPath(pathLeft, silPaint);

    final pathCenter = Path();
    drawShikhara(pathCenter, w * 0.76, bottomY, w * 0.28, size.height * 0.72);
    canvas.drawPath(pathCenter, silPaint);

    final pathRight = Path();
    drawShikhara(pathRight, w * 0.90, bottomY, w * 0.16, size.height * 0.42);
    canvas.drawPath(pathRight, silPaint);

    double mainSpirePeakX = w * 0.76;
    double mainSpirePeakY = bottomY - (size.height * 0.72);

    final flagpolePaint = Paint()
      ..color = const Color(0xFFFF7A00)
      ..strokeWidth = 1.8;
    canvas.drawLine(
      Offset(mainSpirePeakX, mainSpirePeakY),
      Offset(mainSpirePeakX, mainSpirePeakY - 26),
      flagRulesWorkaround(flagpolePaint),
    );

    final flagPath = Path();
    flagPath.moveTo(mainSpirePeakX, mainSpirePeakY - 26);
    flagPath.lineTo(mainSpirePeakX + 18, mainSpirePeakY - 20);
    flagPath.lineTo(mainSpirePeakX, mainSpirePeakY - 14);
    flagPath.close();

    final flagPaint = Paint()
      ..color = const Color(0xFFFF7A00)
      ..style = PaintingStyle.fill;
    canvas.drawPath(flagPath, flagPaint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'ॐ',
        style: TextStyle(color: Colors.black, fontSize: 6, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(mainSpirePeakX + 2, mainSpirePeakY - 22));
  }

  Paint flagRulesWorkaround(Paint p) => p;

  void drawShikhara(Path path, double centerX, double bottomY, double width, double height) {
    double topY = bottomY - height;
    double halfW = width / 2;
    path.moveTo(centerX - halfW, bottomY);
    int tiers = 7;
    for (int i = 0; i < tiers; i++) {
      double pct = i / tiers;
      double nextPct = (i + 1) / tiers;
      double curW = halfW * (1.0 - pct * 0.85);
      double curY = bottomY - (height * pct);
      double nextY = bottomY - (height * nextPct);
      path.lineTo(centerX - curW, curY);
      path.lineTo(centerX - curW, nextY);
    }
    path.lineTo(centerX - 2, topY - 4);
    path.lineTo(centerX + 2, topY - 4);
    for (int i = tiers - 1; i >= 0; i--) {
      double pct = i / tiers;
      double nextPct = (i + 1) / tiers;
      double curW = halfW * (1.0 - pct * 0.85);
      double curY = bottomY - (height * pct);
      double nextY = bottomY - (height * nextPct);
      path.lineTo(centerX + curW, nextY);
      path.lineTo(centerX + curW, curY);
    }
    path.lineTo(centerX + halfW, bottomY);
    path.close();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
