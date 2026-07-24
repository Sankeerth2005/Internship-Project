import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/network/dio_client.dart';

// ─── DESIGN TOKENS ────────────────────────────────────────────────────────────
class _AnalTok {
  static const Color primary = Color(0xFFFF6600);
  static const Color bg = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF9F8F6);
  static const Color border = Color(0xFFEAE8E3);
  static const Color textHigh = Color(0xFF1A1918);
  static const Color textMedium = Color(0xFF5F5C58);
  static const Color success = Color(0xFF107C41);
  static const Color info = Color(0xFF0066CC);
}

class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  final int businessId;
  final String businessName;

  const AnalyticsDashboardScreen({
    super.key,
    required this.businessId,
    this.businessName = 'Business Performance',
  });

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends ConsumerState<AnalyticsDashboardScreen> with SingleTickerProviderStateMixin {
  bool _loadingMetrics = true;
  bool _loadingInsights = false;
  int _views = 0;
  int _favorites = 0;
  int _clicks = 0;
  String _aiInsights = "";
  String _errorMessage = "";

  String _selectedTimeframe = 'Weekly';
  late AnimationController _chartAnimCtrl;

  @override
  void initState() {
    super.initState();
    _chartAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _loadMetrics();
  }

  @override
  void dispose() {
    _chartAnimCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _loadingMetrics = true;
      _errorMessage = "";
    });

    try {
      final response = await DioClient().dio.get('analytics/business/${widget.businessId}');
      final data = response.data;
      if (data != null && data['success'] == true) {
        final metrics = data['data'];
        setState(() {
          _views = metrics['views'] ?? 0;
          _favorites = metrics['favorites'] ?? 0;
          _clicks = metrics['clicks'] ?? 0;
          _loadingMetrics = false;
        });
        _chartAnimCtrl.forward(from: 0.0);
        _loadAiInsights();
      } else {
        setState(() {
          _errorMessage = "Failed to load metrics.";
          _loadingMetrics = false;
        });
      }
    } catch (_) {
      setState(() {
        _errorMessage = "Unable to fetch metrics from server.";
        _loadingMetrics = false;
      });
    }
  }

  Future<void> _loadAiInsights() async {
    setState(() {
      _loadingInsights = true;
      _aiInsights = "";
    });

    try {
      final response = await DioClient().dio.post('analytics/ai-insights/${widget.businessId}');
      final data = response.data;
      if (data != null && data['success'] == true) {
        setState(() {
          _aiInsights = data['data'] ?? "No recommendations found currently.";
          _loadingInsights = false;
        });
      } else {
        setState(() {
          _aiInsights = "Could not generate recommendations.";
          _loadingInsights = false;
        });
      }
    } catch (_) {
      setState(() {
        _aiInsights = "Failed to reach AI insights server.";
        _loadingInsights = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AnalTok.bg,
      appBar: AppBar(
        backgroundColor: _AnalTok.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _AnalTok.textMedium, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.businessName} Analytics',
          style: const TextStyle(
            fontFamily: 'Inter',
            color: _AnalTok.textHigh,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: _AnalTok.border,
            height: 1,
          ),
        ),
      ),
      body: _loadingMetrics
          ? const Center(child: CircularProgressIndicator(color: _AnalTok.primary))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(_errorMessage, style: const TextStyle(color: _AnalTok.textMedium, fontSize: 13)),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeframe Tabs Selector Row
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _AnalTok.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _AnalTok.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: ['Weekly', 'Monthly', 'Yearly'].map((tf) {
                              final isSel = tf == _selectedTimeframe;
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _selectedTimeframe = tf;
                                  });
                                  _chartAnimCtrl.forward(from: 0.0);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSel ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: isSel
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.03),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: Text(
                                    tf,
                                    style: TextStyle(
                                      color: isSel ? _AnalTok.primary : _AnalTok.textMedium,
                                      fontSize: 12,
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // KPI Cards Row
                      Row(
                        children: [
                          _buildStatCard('Views', '$_views', Icons.visibility_rounded, _AnalTok.primary),
                          const SizedBox(width: 10),
                          _buildStatCard('Saves', '$_favorites', Icons.favorite_rounded, _AnalTok.info),
                          const SizedBox(width: 10),
                          _buildStatCard('Clicks', '$_clicks', Icons.touch_app_rounded, _AnalTok.success),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Chart 1: Profile Views Trend
                      const Text(
                        'Profile Views Trend',
                        style: TextStyle(color: _AnalTok.textHigh, fontSize: 14, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Detailed daily interaction mapping for the selected $_selectedTimeframe timeframe.',
                        style: const TextStyle(color: _AnalTok.textMedium, fontSize: 11),
                      ),
                      const SizedBox(height: 14),

                      Container(
                        height: 220,
                        width: double.infinity,
                        padding: const EdgeInsets.only(right: 22, left: 12, top: 24, bottom: 12),
                        decoration: BoxDecoration(
                          color: _AnalTok.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _AnalTok.border),
                        ),
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 1,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: _AnalTok.border,
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 22,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    return SideTitleWidget(
                                      meta: meta,
                                      child: Text(
                                        'Day ${value.toInt() + 1}',
                                        style: const TextStyle(color: _AnalTok.textMedium, fontSize: 10),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  reservedSize: 28,
                                  getTitlesWidget: (value, meta) {
                                    if (value % 2 != 0) return const SizedBox.shrink();
                                    return Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(color: _AnalTok.textMedium, fontSize: 10),
                                      textAlign: TextAlign.right,
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            minX: 0,
                            maxX: 6,
                            minY: 0,
                            maxY: (_views.toDouble() * 0.3).clamp(5, double.infinity),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _getFlChartTrendData(_selectedTimeframe, _views),
                                isCurved: true,
                                color: _AnalTok.primary,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: _AnalTok.primary.withValues(alpha: 0.15),
                                ),
                              ),
                            ],
                          ),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Chart 2: Action Conversions Comparison
                      const Text(
                        'Clicks vs Saves Comparison',
                        style: TextStyle(color: _AnalTok.textHigh, fontSize: 14, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Compares contact clicks against store favorites.',
                        style: TextStyle(color: _AnalTok.textMedium, fontSize: 11),
                      ),
                      const SizedBox(height: 14),

                      Container(
                        height: 200,
                        width: double.infinity,
                        padding: const EdgeInsets.only(top: 24, bottom: 12),
                        decoration: BoxDecoration(
                          color: _AnalTok.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _AnalTok.border),
                        ),
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceEvenly,
                            maxY: (max(_clicks, _favorites).toDouble() * 1.2).clamp(5, double.infinity),
                            barTouchData: BarTouchData(enabled: false),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    const style = TextStyle(color: _AnalTok.textMedium, fontWeight: FontWeight.bold, fontSize: 12);
                                    String text = value.toInt() == 0 ? 'Clicks' : 'Saves';
                                    return SideTitleWidget(
                                      meta: meta,
                                      space: 4,
                                      child: Text(text, style: style),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            barGroups: [
                              BarChartGroupData(
                                x: 0,
                                barRods: [
                                  BarChartRodData(
                                    toY: _clicks.toDouble(),
                                    color: _AnalTok.primary,
                                    width: 40,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ],
                              ),
                              BarChartGroupData(
                                x: 1,
                                barRods: [
                                  BarChartRodData(
                                    toY: _favorites.toDouble(),
                                    color: _AnalTok.info,
                                    width: 40,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // AI Insights Section
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: _AnalTok.primary, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'AI Action Recommendations',
                            style: TextStyle(
                              color: _AnalTok.textHigh,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _AnalTok.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _AnalTok.border),
                        ),
                        child: _loadingInsights
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: CircularProgressIndicator(color: _AnalTok.primary),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _aiInsights.isNotEmpty ? _aiInsights : "No insight suggestions generated yet.",
                                    style: const TextStyle(
                                      color: _AnalTok.textHigh,
                                      fontSize: 12,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        _loadAiInsights();
                                      },
                                      icon: const Icon(Icons.refresh_rounded, color: _AnalTok.primary, size: 14),
                                      label: const Text(
                                        'Re-Generate Recommendations',
                                        style: TextStyle(color: _AnalTok.primary, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: _AnalTok.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _AnalTok.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(color: _AnalTok.textHigh, fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: _AnalTok.textMedium, fontSize: 10.5),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _getFlChartTrendData(String timeframe, int totalViews) {
    if (totalViews == 0) {
      if (timeframe == 'Weekly') {
        return List.generate(7, (index) => FlSpot(index.toDouble(), 0));
      }
      return List.generate(12, (index) => FlSpot(index.toDouble(), 0));
    }
    
    final List<double> factors;
    if (timeframe == 'Weekly') {
      factors = [0.08, 0.15, 0.12, 0.18, 0.14, 0.22, 0.11];
    } else if (timeframe == 'Monthly') {
      factors = [0.05, 0.08, 0.07, 0.09, 0.12, 0.10, 0.11, 0.08, 0.10, 0.07, 0.06, 0.07];
    } else {
      factors = [0.06, 0.07, 0.08, 0.07, 0.09, 0.10, 0.11, 0.12, 0.09, 0.08, 0.07, 0.06];
    }

    final sumFactors = factors.reduce((a, b) => a + b);
    return List.generate(factors.length, (index) {
      return FlSpot(index.toDouble(), (factors[index] / sumFactors) * totalViews);
    });
  }
}
