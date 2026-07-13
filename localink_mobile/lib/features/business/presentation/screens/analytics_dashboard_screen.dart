import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';

class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  final int businessId;
  final String businessName;

  const AnalyticsDashboardScreen({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends ConsumerState<AnalyticsDashboardScreen> {
  bool _loadingMetrics = true;
  bool _loadingInsights = false;
  int _views = 0;
  int _favorites = 0;
  int _clicks = 0;
  String _aiInsights = "";
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _loadMetrics();
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
        // Auto-load AI insights once metrics load
        _loadAiInsights();
      } else {
        setState(() {
          _errorMessage = "Failed to load metrics data.";
          _loadingMetrics = false;
        });
      }
    } catch (e) {
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
          _aiInsights = data['data'] ?? "No suggestions found currently.";
          _loadingInsights = false;
        });
      } else {
        setState(() {
          _aiInsights = "Could not generate suggestions.";
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

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFC8A97E), size: 24),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.businessName} Analytics',
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loadingMetrics
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC8A97E)))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(_errorMessage, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Weekly Stats Title
                      const Text(
                        'Weekly Performance Metrics',
                        style: TextStyle(
                          color: Color(0xFFC8A97E),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Metrics Cards Row
                      Row(
                        children: [
                          _buildStatCard('Profile Views', '$_views', Icons.visibility),
                          const SizedBox(width: 10),
                          _buildStatCard('Favorites', '$_favorites', Icons.favorite),
                          const SizedBox(width: 10),
                          _buildStatCard('Contact Clicks', '$_clicks', Icons.touch_app),
                        ],
                      ),
                      const SizedBox(height: 25),

                      // AI Smart Insights Section
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Color(0xFFC8A97E), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'AI Smart Action Insights',
                            style: TextStyle(
                              color: Color(0xFFC8A97E),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2E2416), Color(0xFF1C1812)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFC8A97E).withValues(alpha: 0.2)),
                        ),
                        child: _loadingInsights
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: CircularProgressIndicator(color: Color(0xFFC8A97E)),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _aiInsights,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      height: 1.6,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: _loadAiInsights,
                                      icon: const Icon(Icons.refresh, color: Color(0xFFC8A97E), size: 14),
                                      label: const Text(
                                        'Re-Generate Recommendations',
                                        style: TextStyle(color: Color(0xFFC8A97E), fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 25),

                      // QR Code Marketing Material section
                      const Text(
                        'Storefront Marketing Material',
                        style: TextStyle(
                          color: Color(0xFFC8A97E),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.qr_code_2,
                                color: Colors.black,
                                size: 80,
                              ),
                            ),
                            const SizedBox(width: 20),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Download Storefront QR Code',
                                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Print and place this gold-themed QR code on your counter so customers can scan it to instantly open your details page and write reviews.',
                                    style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
