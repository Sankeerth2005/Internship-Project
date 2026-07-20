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
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFFF7A00), size: 24),
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
        backgroundColor: const Color(0xFF161616),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFFF7A00), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.businessName} Analytics',
          style: const TextStyle(
            fontFamily: 'Inter',
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withValues(alpha: 0.05),
            height: 1,
          ),
        ),
      ),
      body: _loadingMetrics
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A00)))
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
                          color: Color(0xFFFF7A00),
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
                          Icon(Icons.auto_awesome, color: Color(0xFFFF7A00), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'AI Smart Action Insights',
                            style: TextStyle(
                              color: Color(0xFFFF7A00),
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
                            colors: [Color(0xFF1A1200), Color(0xFF120D00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFF7A00).withValues(alpha: 0.2)),
                        ),
                        child: _loadingInsights
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: CircularProgressIndicator(color: Color(0xFFFF7A00)),
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
                                      icon: const Icon(Icons.refresh, color: Color(0xFFFF7A00), size: 14),
                                      label: const Text(
                                        'Re-Generate Recommendations',
                                        style: TextStyle(color: Color(0xFFFF7A00), fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
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
