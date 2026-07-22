import 'package:flutter/material.dart';
import '../../data/models/admin_business_dto.dart';
import 'business_approval_sheet.dart';

class AiInsightsPanel extends StatelessWidget {
  final List<AdminBusinessDto> businesses;
  final VoidCallback? onRefresh;

  const AiInsightsPanel({
    super.key,
    required this.businesses,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final insights = _generateInsights();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF9B51E0).withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF9B51E0), size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'AI Actionable Insights',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (insights.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9B51E0).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${insights.length} Alerts',
                    style: const TextStyle(
                      color: Color(0xFF9B51E0),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (insights.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 36),
                    SizedBox(height: 10),
                    Text(
                      'All systems clean. No anomalies detected.',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: insights.length,
              itemBuilder: (context, idx) {
                final item = insights[idx];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item.icon, color: item.color, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.description,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                                height: 1.35,
                              ),
                            ),
                            if (item.business != null) ...[
                              const SizedBox(height: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF9B51E0),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  minimumSize: Size.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => BusinessApprovalSheet(
                                      business: item.business!,
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Review Listing',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  List<_InsightData> _generateInsights() {
    final List<_InsightData> list = [];

    // 1. Scan for Deletion Requests
    final deletions = businesses.where((b) => b.status.toLowerCase() == 'deletionrequested').toList();
    for (final b in deletions) {
      list.add(
        _InsightData(
          title: 'Immediate Deletion Review',
          description: '"${b.name}" requested permanent deletion. Verification of compliance is required.',
          icon: Icons.delete_forever_rounded,
          color: Colors.redAccent,
          business: b,
        ),
      );
    }

    // 2. Scan for Temporary Closure Requests
    final closures = businesses.where((b) => b.isTemporaryClosurePending).toList();
    for (final b in closures) {
      list.add(
        _InsightData(
          title: 'Temporary Closure Request',
          description: '"${b.name}" requested temporary closure for ${b.temporaryClosureDays ?? 0} days.',
          icon: Icons.hourglass_top_rounded,
          color: Colors.orangeAccent,
          business: b,
        ),
      );
    }

    // 3. Scan for Pending Approvals
    final pendings = businesses.where((b) => b.status.toLowerCase() == 'pending').toList();
    for (final b in pendings) {
      list.add(
        _InsightData(
          title: 'Unverified Listing',
          description: '"${b.name}" has been created and is waiting for administrator approval.',
          icon: Icons.storefront_rounded,
          color: const Color(0xFFFF7A00),
          business: b,
        ),
      );
    }

    // 4. Scan for Incomplete Listings (Quality control check)
    final incompletes = businesses.where((b) =>
        b.status.toLowerCase() == 'approved' &&
        ((b.phone == null || b.phone!.trim().isEmpty) ||
         (b.email == null || b.email!.trim().isEmpty) ||
         (b.description.length < 15))).toList();
    if (incompletes.isNotEmpty) {
      final sample = incompletes.first;
      list.add(
        _InsightData(
          title: 'Listing Quality Alert',
          description: '"${sample.name}" has unpopulated phone, email, or a short description. Notify listing owner.',
          icon: Icons.warning_amber_rounded,
          color: Colors.amber,
        ),
      );
    }

    return list;
  }
}

class _InsightData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final AdminBusinessDto? business;

  _InsightData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.business,
  });
}
