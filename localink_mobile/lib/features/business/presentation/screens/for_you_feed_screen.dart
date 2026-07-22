import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/dio_client.dart';
import '../../../shared/presentation/widgets/app_back_button.dart';
import '../../../ai/widgets/ai_feed_card.dart';

// ─── DESIGN TOKENS ────────────────────────────────────────────────────────────
class _FeedTok {
  static const Color primary = Color(0xFFFF6600);
  static const Color bg = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFF9F8F6);
  static const Color border = Color(0xFFEAE8E3);
  static const Color textHigh = Color(0xFF1A1918);
  static const Color textMedium = Color(0xFF5F5C58);
}

class ForYouFeedScreen extends ConsumerStatefulWidget {
  const ForYouFeedScreen({super.key});

  @override
  ConsumerState<ForYouFeedScreen> createState() => _ForYouFeedScreenState();
}

class _ForYouFeedScreenState extends ConsumerState<ForYouFeedScreen> {
  bool _loading = true;
  String _greeting = "Namaste! Welcome back to your local guide.";
  String _timeOfDay = "Day";
  String _preferredCategory = "Services";
  List<dynamic> _recommendations = [];
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _loadPersonalizedFeed();
  }

  Future<void> _loadPersonalizedFeed() async {
    setState(() {
      _loading = true;
      _errorMessage = "";
    });

    double? lat;
    double? lng;

    try {
      // Fetch user location
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 4),
          ),
        );
        lat = pos.latitude;
        lng = pos.longitude;
      }
    } catch (_) {
      // Fail silently and use fallbacks
    }

    try {
      final response = await DioClient().dio.get(
        'personalization/feed',
        queryParameters: {
          'lat': ?lat,
          'lng': ?lng,
        },
      );

      final data = response.data;
      if (data != null && data['success'] == true) {
        setState(() {
          _greeting = data['greeting'] ?? _greeting;
          _timeOfDay = data['timeOfDay'] ?? _timeOfDay;
          _preferredCategory = data['preferredCategory'] ?? _preferredCategory;
          _recommendations = data['data'] ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Failed to load personalized content.";
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Unable to reach server. Please check connection.";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _FeedTok.bg,
      appBar: AppBar(
        backgroundColor: _FeedTok.bg,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: AppBackButton(onPressed: () => context.pop()),
        ),
        title: const Text(
          'For You',
          style: TextStyle(
            fontFamily: 'Inter',
            color: _FeedTok.textHigh,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _FeedTok.primary),
            onPressed: _loadPersonalizedFeed,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: _FeedTok.border,
            height: 1,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _FeedTok.primary))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(_errorMessage, style: const TextStyle(color: _FeedTok.textMedium, fontSize: 14)),
                )
              : RefreshIndicator(
                  color: _FeedTok.primary,
                  onRefresh: _loadPersonalizedFeed,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Futuristic Greeting Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF9E4F), Color(0xFFFF6600)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _FeedTok.primary.withValues(alpha: 0.15),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_timeOfDay.toUpperCase()} GUIDE',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _greeting,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  height: 1.45,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Preferred Category Section Title
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: _FeedTok.primary, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Suggested Category: $_preferredCategory',
                              style: const TextStyle(
                                color: _FeedTok.textHigh,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Recommendations List
                        if (_recommendations.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: _FeedTok.cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _FeedTok.border),
                            ),
                            child: const Center(
                              child: Text(
                                'No local recommendations found for this category currently.',
                                style: TextStyle(color: _FeedTok.textMedium, fontSize: 13),
                              ),
                            ),
                          )
                        else
                          ..._recommendations.map((item) => AiFeedCard(item: item)),
                      ],
                    ),
                  ),
                ),
    );
  }
}
