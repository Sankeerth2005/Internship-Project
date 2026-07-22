import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/models/admin_business_dto.dart';

class BusinessStatusPieChart extends StatelessWidget {
  final List<AdminBusinessDto> businesses;

  const BusinessStatusPieChart({
    super.key,
    required this.businesses,
  });

  @override
  Widget build(BuildContext context) {
    final total = businesses.length;
    if (total == 0) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No business data available for chart.',
            style: TextStyle(color: Colors.white30, fontSize: 13),
          ),
        ),
      );
    }

    final approved = businesses.where((b) => b.status.toLowerCase() == 'approved').length;
    final pending = businesses.where((b) => b.status.toLowerCase() == 'pending').length;
    final rejected = businesses.where((b) => b.status.toLowerCase() == 'rejected').length;
    final deletions = businesses.where((b) => b.status.toLowerCase() == 'deletionrequested').length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status Distribution',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: [
                  if (approved > 0)
                    PieChartSectionData(
                      color: const Color(0xFFFF7A00),
                      value: approved.toDouble(),
                      title: 'Appr\n$approved',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  if (pending > 0)
                    PieChartSectionData(
                      color: Colors.amber,
                      value: pending.toDouble(),
                      title: 'Pend\n$pending',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  if (rejected > 0)
                    PieChartSectionData(
                      color: Colors.redAccent,
                      value: rejected.toDouble(),
                      title: 'Rej\n$rejected',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  if (deletions > 0)
                    PieChartSectionData(
                      color: Colors.purpleAccent,
                      value: deletions.toDouble(),
                      title: 'Del\n$deletions',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildLegend('Approved', const Color(0xFFFF7A00)),
              _buildLegend('Pending', Colors.amber),
              _buildLegend('Rejected', Colors.redAccent),
              _buildLegend('Deletion Req', Colors.purpleAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }
}

class EngagementBarChart extends StatelessWidget {
  final Map<String, dynamic> stats;

  const EngagementBarChart({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final clicks = double.tryParse(stats['totalClicks']?.toString() ?? '0') ?? 0.0;
    final views = double.tryParse(stats['totalViews']?.toString() ?? '0') ?? 0.0;
    final reviews = double.tryParse(stats['totalReviews']?.toString() ?? '0') ?? 0.0;

    final maxVal = [clicks, views, reviews, 10.0].reduce((curr, next) => curr > next ? curr : next);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Engagement Funnel',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: maxVal * 1.2,
                barTouchData: BarTouchData(enabled: true),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        String text = '';
                        switch (val.toInt()) {
                          case 0:
                            text = 'Views';
                            break;
                          case 1:
                            text = 'Clicks';
                            break;
                          case 2:
                            text = 'Reviews';
                            break;
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            text,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: views,
                        color: Colors.green,
                        width: 24,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: clicks,
                        color: Colors.blueAccent,
                        width: 24,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: reviews,
                        color: const Color(0xFFFF7A00),
                        width: 24,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
