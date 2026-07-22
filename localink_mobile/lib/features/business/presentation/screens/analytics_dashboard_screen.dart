import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                        height: 180,
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _AnalTok.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _AnalTok.border),
                        ),
                        child: AnimatedBuilder(
                          animation: _chartAnimCtrl,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: _BezierTrendPainter(
                                values: _getMockTrendData(_selectedTimeframe),
                                progress: _chartAnimCtrl.value,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Chart 2: Action Conversions Comparison
                      const Text(
                        'Clicks vs Directions Comparison',
                        style: TextStyle(color: _AnalTok.textHigh, fontSize: 14, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Compares user clicks against map direction queries.',
                        style: TextStyle(color: _AnalTok.textMedium, fontSize: 11),
                      ),
                      const SizedBox(height: 14),

                      Container(
                        height: 180,
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _AnalTok.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _AnalTok.border),
                        ),
                        child: AnimatedBuilder(
                          animation: _chartAnimCtrl,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: _ComparisonBarPainter(
                                clicks: _clicks.toDouble(),
                                directions: (_favorites * 1.5).roundToDouble(), // Simulating directions
                                progress: _chartAnimCtrl.value,
                              ),
                            );
                          },
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

  List<double> _getMockTrendData(String timeframe) {
    if (timeframe == 'Weekly') {
      return [120, 240, 180, 320, 290, 410, 380];
    } else if (timeframe == 'Monthly') {
      return [100, 180, 150, 220, 310, 280, 420, 390, 490, 450, 520, 580];
    } else {
      return [800, 1200, 1100, 1500, 1800, 1700, 2100, 2300, 2000, 2400, 2800, 3200];
    }
  }
}

// ─── BEZIER LINE CHART PAINTER ────────────────────────────────────────────────
class _BezierTrendPainter extends CustomPainter {
  final List<double> values;
  final double progress;

  _BezierTrendPainter({required this.values, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final double maxVal = values.reduce(max);
    final double minVal = values.reduce(min);
    final double range = maxVal - minVal == 0 ? 1 : maxVal - minVal;

    final double widthStep = size.width / (values.length - 1);
    final double heightScale = size.height * 0.7;
    final double heightOffset = size.height * 0.15;

    final path = Path();
    final fillPath = Path();

    // 1. Draw horizontal gridline marks
    final gridPaint = Paint()
      ..color = _AnalTok.border
      ..strokeWidth = 1.0;
    
    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Build Bezier curve path
    for (int i = 0; i < values.length; i++) {
      final double x = i * widthStep;
      final double y = size.height - ((values[i] - minVal) / range * heightScale + heightOffset);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final prevX = (i - 1) * widthStep;
        final prevY = size.height - ((values[i - 1] - minVal) / range * heightScale + heightOffset);
        final controlX1 = prevX + widthStep / 2;
        final controlY1 = prevY;
        final controlX2 = prevX + widthStep / 2;
        final controlY2 = y;

        path.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
        fillPath.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
      }
    }

    fillPath.lineTo((values.length - 1) * widthStep, size.height);
    fillPath.close();

    // 3. Draw gradient fill (clipped by progress animation)
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          _AnalTok.primary.withValues(alpha: 0.25),
          _AnalTok.primary.withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, gradientPaint);

    final linePaint = Paint()
      ..color = _AnalTok.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Draw active end pointer circle
    if (progress > 0) {
      final double currentIdxDouble = (values.length - 1) * progress;
      final int lowerIdx = currentIdxDouble.floor();
      final int upperIdx = currentIdxDouble.ceil().clamp(0, values.length - 1);
      final double t = currentIdxDouble - lowerIdx;

      final double x = currentIdxDouble * widthStep;
      final double y1 = size.height - ((values[lowerIdx] - minVal) / range * heightScale + heightOffset);
      final double y2 = size.height - ((values[upperIdx] - minVal) / range * heightScale + heightOffset);
      final double y = y1 + (y2 - y1) * t;

      final pointerOutlinePaint = Paint()..color = Colors.white;
      final pointerFillPaint = Paint()..color = _AnalTok.primary;

      canvas.drawCircle(Offset(x, y), 6, pointerOutlinePaint);
      canvas.drawCircle(Offset(x, y), 4, pointerFillPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BezierTrendPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.values != values;
  }
}

// ─── COMPARISON BAR CHART PAINTER ────────────────────────────────────────────
class _ComparisonBarPainter extends CustomPainter {
  final double clicks;
  final double directions;
  final double progress;

  _ComparisonBarPainter({required this.clicks, required this.directions, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double maxVal = max(clicks, directions);
    final double scaleMax = maxVal == 0 ? 1 : maxVal * 1.25;

    final barWidth = size.width * 0.16;
    final spacing = size.width * 0.22;

    // Draw grid marks
    final gridPaint = Paint()
      ..color = _AnalTok.border
      ..strokeWidth = 1.0;
    
    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Bar 1: Clicks (Primary color)
    final double clicksHeight = (clicks / scaleMax) * size.height * progress;
    final clicksRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.2 - barWidth / 2,
        size.height - clicksHeight,
        barWidth,
        clicksHeight,
      ),
      const Radius.circular(8),
    );
    final clicksPaint = Paint()..color = _AnalTok.primary;
    canvas.drawRRect(clicksRect, clicksPaint);

    // Bar 2: Directions (Blue/Info color)
    final double directionsHeight = (directions / scaleMax) * size.height * progress;
    final directionsRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.2 + spacing - barWidth / 2,
        size.height - directionsHeight,
        barWidth,
        directionsHeight,
      ),
      const Radius.circular(8),
    );
    final directionsPaint = Paint()..color = _AnalTok.info;
    canvas.drawRRect(directionsRect, directionsPaint);

    // Draw Labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Label 1
    textPainter.text = const TextSpan(
      text: 'Clicks',
      style: TextStyle(color: _AnalTok.textMedium, fontSize: 10, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.width * 0.2 - textPainter.width / 2, size.height - 18 - clicksHeight.clamp(20, size.height)),
    );

    // Label 2
    textPainter.text = const TextSpan(
      text: 'Directions',
      style: TextStyle(color: _AnalTok.textMedium, fontSize: 10, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.width * 0.2 + spacing - textPainter.width / 2, size.height - 18 - directionsHeight.clamp(20, size.height)),
    );
  }

  @override
  bool shouldRepaint(covariant _ComparisonBarPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.clicks != clicks || oldDelegate.directions != directions;
  }
}
