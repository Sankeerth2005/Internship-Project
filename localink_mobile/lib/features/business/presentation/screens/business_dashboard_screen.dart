import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/business_provider.dart';
import '../../data/models/business_models.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/providers/auth_state.dart';
import '../../../../core/network/signalr_service.dart';

// ─── DESIGN TOKENS ────────────────────────────────────────────────────────────
class _DashTok {
  static const Color primary = Color(0xFFFF6600);
  static const Color primaryLight = Color(0xFFFFF0E6);
  static const Color bg = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF9F8F6);
  static const Color border = Color(0xFFEAE8E3);
  static const Color textHigh = Color(0xFF1A1918);
  static const Color textMedium = Color(0xFF5F5C58);
  static const Color textLow = Color(0xFF9F9B96);
  static const Color success = Color(0xFF107C41);
  static const Color successLight = Color(0xFFE2F6EA);
  static const Color info = Color(0xFF0066CC);
  static const Color warning = Color(0xFFB37400);
  static const Color warningLight = Color(0xFFFFF9E6);
  static const Color danger = Color(0xFFC42B1C);
  static const Color dangerLight = Color(0xFFFDF0ED);
  static const Color ai = Color(0xFF7030A0);
  static const Color aiLight = Color(0xFFF2EBF7);
}

class BusinessDashboardScreen extends ConsumerStatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  ConsumerState<BusinessDashboardScreen> createState() => _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends ConsumerState<BusinessDashboardScreen> {
  int? _selectedBusinessId;

  @override
  Widget build(BuildContext context) {
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
        backgroundColor: _DashTok.bg,
        appBar: AppBar(
          backgroundColor: _DashTok.bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _DashTok.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.storefront_rounded, color: _DashTok.primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Business Suite',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: _DashTok.textHigh,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: _DashTok.textMedium),
              tooltip: 'Refresh',
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.read(myBusinessesProvider.notifier).refresh();
              },
            ),
            IconButton(
              icon: const Icon(Icons.person_outline_rounded, color: _DashTok.textMedium),
              tooltip: 'Profile',
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push('/owner-profile');
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: _DashTok.danger),
              tooltip: 'Logout',
              onPressed: () {
                HapticFeedback.mediumImpact();
                if (authState is AuthAuthenticated) {
                  SignalRService().disconnect(authState.userId);
                }
                ref.read(authProvider.notifier).logout();
              },
            ),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              color: _DashTok.border,
              height: 1,
            ),
          ),
        ),
        body: myBusinessesAsync.when(
          data: (businesses) {
            if (businesses.isEmpty) {
              return _buildEmptyState(context);
            }

            // Select default business if not set or not in lists anymore
            if (_selectedBusinessId == null || !businesses.any((b) => b.businessId == _selectedBusinessId)) {
              _selectedBusinessId = businesses.first.businessId;
            }

            final activeBusiness = businesses.firstWhere((b) => b.businessId == _selectedBusinessId);

            return RefreshIndicator(
              color: _DashTok.primary,
              onRefresh: () async {
                await ref.read(myBusinessesProvider.notifier).refresh();
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  // Business Picker Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (businesses.length > 1) ...[
                            const Text(
                              'Switch Business Store',
                              style: TextStyle(
                                color: _DashTok.textMedium,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: _DashTok.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _DashTok.border),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _selectedBusinessId,
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _DashTok.textMedium),
                                  dropdownColor: _DashTok.bg,
                                  style: const TextStyle(
                                    color: _DashTok.textHigh,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  items: businesses.map((b) {
                                    return DropdownMenuItem<int>(
                                      value: b.businessId,
                                      child: Text(b.businessName),
                                    );
                                  }).toList(),
                                  onChanged: (id) {
                                    if (id != null) {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        _selectedBusinessId = id;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Hero Command Center Banner
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: _buildHeroCommandCenter(context, activeBusiness),
                    ),
                  ),

                  // KPI Grid Title
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Analytics Insights',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: _DashTok.textHigh,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              context.push('/analytics/${activeBusiness.businessId}', extra: activeBusiness);
                            },
                            child: const Row(
                              children: [
                                Text(
                                  'View Details',
                                  style: TextStyle(
                                    color: _DashTok.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios_rounded, color: _DashTok.primary, size: 10),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // KPI Cards Grid
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.38,
                      children: [
                        _buildKpiCard('Search Views', '1,428', '+14%', Icons.troubleshoot_rounded, _DashTok.info),
                        _buildKpiCard('Profile Views', '842', '+18%', Icons.visibility_rounded, _DashTok.primary),
                        _buildKpiCard('Directions clicks', '230', '+8%', Icons.directions_rounded, _DashTok.success),
                        _buildKpiCard('Phone Clicks', '125', '+11%', Icons.phone_rounded, _DashTok.warning),
                      ],
                    ),
                  ),

                  // AI Growth Insights Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _DashTok.aiLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.auto_awesome, color: _DashTok.ai, size: 14),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'AI Smart Growth Advisor',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: _DashTok.textHigh,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _buildAiCard(
                            '🏆 Business visibility increased by 18% this week.',
                            'View Stats',
                            () => context.push('/analytics/${activeBusiness.businessId}', extra: activeBusiness),
                          ),
                          const SizedBox(height: 10),
                          _buildAiCard(
                            '📸 Listing status is approved! Add secondary gallery photos to double local views.',
                            'Manage Gallery',
                            () => context.push('/edit-business/${activeBusiness.businessId}', extra: activeBusiness),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Quick Actions Title
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                      child: const Text(
                        'Command Controls',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: _DashTok.textHigh,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),

                  // Quick Actions Grid Row
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildActionBtn(
                              icon: Icons.edit_rounded,
                              label: 'Edit Profile',
                              onTap: () {
                                HapticFeedback.lightImpact();
                                context.push('/edit-business/${activeBusiness.businessId}', extra: activeBusiness);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildActionBtn(
                              icon: activeBusiness.isTemporarilyClosed
                                  ? Icons.play_arrow_rounded
                                  : Icons.pause_rounded,
                              label: activeBusiness.isTemporarilyClosed ? 'Reopen Store' : 'Temp Closure',
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                _showTemporaryClosureDialog(context, ref, activeBusiness);
                              },
                              accentColor: activeBusiness.isTemporarilyClosed ? _DashTok.success : _DashTok.warning,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildActionBtn(
                              icon: Icons.delete_outline_rounded,
                              label: 'Delete Listing',
                              onTap: () {
                                HapticFeedback.heavyImpact();
                                _showDeletionDialog(context, ref, activeBusiness);
                              },
                              accentColor: _DashTok.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Recent Timeline Activity
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
                      child: const Text(
                        'Recent Suite Logs',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: _DashTok.textHigh,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildTimelineItem(
                          icon: Icons.star_rounded,
                          title: 'New Review Received',
                          desc: 'Sanket left a 5-star review for your listing.',
                          time: '3h ago',
                          color: _DashTok.primary,
                        ),
                        _buildTimelineItem(
                          icon: Icons.edit_note_rounded,
                          title: 'Listing Details Updated',
                          desc: 'Metadata and tags synced to local directories.',
                          time: '1d ago',
                          color: _DashTok.info,
                        ),
                        _buildTimelineItem(
                          icon: Icons.verified_user_rounded,
                          title: 'Store Approved',
                          desc: 'Your listing is now verified and active.',
                          time: '5d ago',
                          color: _DashTok.success,
                        ),
                      ]),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 60)),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: _DashTok.primary)),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded, color: _DashTok.danger, size: 48),
                  const SizedBox(height: 12),
                  Text('Failed to sync details: $err', style: const TextStyle(color: _DashTok.textMedium), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.read(myBusinessesProvider.notifier).refresh(),
                    style: ElevatedButton.styleFrom(backgroundColor: _DashTok.primary, foregroundColor: Colors.white),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _DashTok.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_business_rounded, color: _DashTok.primary, size: 44),
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome, Store Owner!',
              style: TextStyle(color: _DashTok.textHigh, fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            const Text(
              'Register your business, services, or stores to gain neighborhood customers.',
              style: TextStyle(color: _DashTok.textMedium, fontSize: 13, height: 1.45),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                context.push('/register-business');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: _DashTok.primary,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: _DashTok.primary.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Register Store Now',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCommandCenter(BuildContext context, BusinessDto b) {
    final isApproved = b.status?.toLowerCase() == 'approved';
    Color statusColor = isApproved ? _DashTok.success : _DashTok.warning;
    Color statusBg = isApproved ? _DashTok.successLight : _DashTok.warningLight;
    var statusText = b.status ?? 'Pending Verification';

    if (b.status?.toLowerCase() == 'deletionrequested') {
      statusColor = _DashTok.danger;
      statusBg = _DashTok.dangerLight;
      statusText = 'Deletion Requested';
    } else if (b.isTemporarilyClosed) {
      statusColor = _DashTok.danger;
      statusBg = _DashTok.dangerLight;
      statusText = 'Temporarily Closed';
    }

    // Health score calculations (Logo uploaded, description length, address etc)
    int score = 40;
    if (b.photos.isNotEmpty) score += 20;
    if (b.description.length > 20) score += 20;
    if (b.email.isNotEmpty) score += 10;
    if (b.website.isNotEmpty) score += 10;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6600), Color(0xFFFF8533)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _DashTok.primary.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Verification Badge Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isApproved)
                        const Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Business Name
                  Text(
                    b.businessName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Owner info
                  Text(
                    'Listing Owner • ${b.email}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Quick launch CTA
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push('/business-detail/${b.businessId}');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Preview Listing',
                        style: TextStyle(
                          color: _DashTok.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Health Score Ring Indicator
            Column(
              children: [
                SizedBox(
                  height: 64,
                  width: 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: score / 100,
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                        strokeWidth: 5.5,
                      ),
                      Text(
                        '$score%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Profile Health',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String count, String trend, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _DashTok.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _DashTok.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _DashTok.successLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trend,
                  style: const TextStyle(color: _DashTok.success, fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: const TextStyle(
                  color: _DashTok.textHigh,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(color: _DashTok.textMedium, fontSize: 10.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiCard(String title, String cta, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _DashTok.aiLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _DashTok.ai.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: _DashTok.textHigh, fontSize: 11.5, height: 1.4),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _DashTok.ai,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                cta,
                style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? accentColor,
  }) {
    final color = accentColor ?? _DashTok.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String desc,
    required String time,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _DashTok.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _DashTok.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: _DashTok.textHigh, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      time,
                      style: const TextStyle(color: _DashTok.textLow, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: const TextStyle(color: _DashTok.textMedium, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTemporaryClosureDialog(BuildContext context, WidgetRef ref, BusinessDto business) {
    if (business.isTemporarilyClosed) {
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: _DashTok.bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Reopen Business', style: TextStyle(color: _DashTok.textHigh, fontWeight: FontWeight.bold)),
          content: Text(
            'Your business "${business.businessName}" is currently marked as temporarily closed. Would you like to reopen it now?',
            style: const TextStyle(color: _DashTok.textMedium, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: _DashTok.textLow)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _DashTok.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                final success = await ref.read(myBusinessesProvider.notifier).cancelTemporaryClosure(business.businessId);
                if (context.mounted) {
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Business reopened successfully.' : 'Failed to reopen business.'),
                      backgroundColor: _DashTok.success,
                    ),
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
            backgroundColor: _DashTok.bg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.pause_circle_outline_rounded, color: _DashTok.warning, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Temporary Closure',
                    style: const TextStyle(color: _DashTok.textHigh, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reason for temporary closure is required.',
                  style: TextStyle(color: _DashTok.textMedium, fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  style: const TextStyle(color: _DashTok.textHigh, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Enter reason (e.g. renovation, vacation)...',
                    hintStyle: const TextStyle(color: _DashTok.textLow, fontSize: 12),
                    filled: true,
                    fillColor: _DashTok.surface,
                    errorText: errorMessage,
                    errorStyle: const TextStyle(color: _DashTok.danger, fontSize: 11),
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _DashTok.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _DashTok.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _DashTok.primary),
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
                const Text('Duration:', style: TextStyle(color: _DashTok.textHigh, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: _DashTok.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _DashTok.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: closureDays,
                      dropdownColor: _DashTok.bg,
                      isExpanded: true,
                      style: const TextStyle(color: _DashTok.textHigh, fontSize: 13),
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
                child: const Text('Cancel', style: TextStyle(color: _DashTok.textLow)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _DashTok.warning,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
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
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.clearSnackBars();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Temporary closure requested.' : 'Failed to request closure.'),
                        backgroundColor: _DashTok.warning,
                      ),
                    );
                  }
                },
                child: const Text('Request Closure', style: TextStyle(fontWeight: FontWeight.bold)),
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
            backgroundColor: _DashTok.bg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.delete_forever_rounded, color: _DashTok.danger, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Delete Listing',
                  style: TextStyle(color: _DashTok.textHigh, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to request permanent deletion of "${business.businessName}"? A mandatory reason is required for review.',
                  style: const TextStyle(color: _DashTok.textMedium, fontSize: 12.5, height: 1.4),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  style: const TextStyle(color: _DashTok.textHigh, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Enter reason for deletion...',
                    hintStyle: const TextStyle(color: _DashTok.textLow, fontSize: 12),
                    filled: true,
                    fillColor: _DashTok.surface,
                    errorText: errorMessage,
                    errorStyle: const TextStyle(color: _DashTok.danger, fontSize: 11),
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _DashTok.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _DashTok.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _DashTok.danger),
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
                child: const Text('Cancel', style: TextStyle(color: _DashTok.textLow)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _DashTok.danger,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
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
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.clearSnackBars();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Deletion request submitted.' : 'Failed to request deletion.'),
                        backgroundColor: _DashTok.danger,
                      ),
                    );
                  }
                },
                child: const Text('Delete Listing', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }
}
