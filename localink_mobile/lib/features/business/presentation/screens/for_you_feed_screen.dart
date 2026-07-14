import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/models/business_models.dart';

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
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 4),
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
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
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
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'For You',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFF7A00)),
            onPressed: _loadPersonalizedFeed,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A00)))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(_errorMessage, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                )
              : RefreshIndicator(
                  color: const Color(0xFFFF7A00),
                  onRefresh: _loadPersonalizedFeed,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Futuristic Greeting Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2E2416), Color(0xFF1A150E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFF7A00).withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.auto_awesome, color: Color(0xFFFF7A00), size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_timeOfDay.toUpperCase()} GUIDE',
                                    style: const TextStyle(
                                      color: Color(0xFFFF7A00),
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
                                  height: 1.4,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),

                        // Preferred Category Section Title
                        Row(
                          children: [
                            const Icon(Icons.star, color: Color(0xFFFF7A00), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Suggested Category: $_preferredCategory',
                              style: const TextStyle(
                                color: Color(0xFFFF7A00),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        // Recommendations List
                        if (_recommendations.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'No local recommendations found for this category currently.',
                                style: TextStyle(color: Colors.white38, fontSize: 12),
                              ),
                            ),
                          )
                        else
                          ..._recommendations.map((item) {
                            final List<dynamic> photos = item['photos'] ?? [];
                            final photoUrl = photos.isNotEmpty
                                ? '${Uri.parse(DioClient().dio.options.baseUrl).origin}${photos.first}'
                                : null;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => context.push('/business-detail/${item['businessId']}'),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (photoUrl != null)
                                      ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(16),
                                          topRight: Radius.circular(16),
                                        ),
                                        child: Image.network(
                                          photoUrl,
                                          height: 140,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            height: 140,
                                            color: const Color(0xFF2A2A2A),
                                            child: const Icon(Icons.business, color: Colors.white24, size: 40),
                                          ),
                                        ),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.all(15),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['businessName'] ?? '',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item['description'] ?? '',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on, color: Color(0xFFFF7A00), size: 12),
                                              const SizedBox(width: 4),
                                              Text(
                                                item['city'] ?? '',
                                                style: const TextStyle(color: Colors.white38, fontSize: 11),
                                              ),
                                              const Spacer(),
                                              Text(
                                                '${item['categoryName']} • ${item['subcategoryName']}',
                                                style: const TextStyle(color: Color(0xFFFF7A00), fontSize: 11, fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                      ],
                    ),
                  ),
                ),
    );
  }
}
