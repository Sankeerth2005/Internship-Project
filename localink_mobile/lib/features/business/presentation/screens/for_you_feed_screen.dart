import 'package:dio/dio.dart';
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
  String _greeting = 'Namaste! Welcome back to your local guide.';
  String _timeOfDay = 'Day';
  String _preferredCategory = 'Services';
  List<dynamic> _recommendations = [];
  String _errorMessage = '';
  bool _locationRequired = false;
  String? _emptyMessage;

  @override
  void initState() {
    super.initState();
    _loadPersonalizedFeed();
  }

  Future<({double? lat, double? lng, bool denied})> _resolveLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return (lat: null, lng: null, denied: true);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return (lat: null, lng: null, denied: true);
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 6),
        ),
      );
      return (lat: pos.latitude, lng: pos.longitude, denied: false);
    } catch (_) {
      return (lat: null, lng: null, denied: true);
    }
  }

  Future<void> _loadPersonalizedFeed() async {
    setState(() {
      _loading = true;
      _errorMessage = '';
      _locationRequired = false;
      _emptyMessage = null;
    });

    final location = await _resolveLocation();
    final lat = location.lat;
    final lng = location.lng;

    if (lat == null || lng == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _locationRequired = true;
        _recommendations = [];
        _emptyMessage =
            'Location is required for your For You feed. Enable location to see nearby businesses.';
      });
      return;
    }

    try {
      final response = await DioClient().dio.get(
        'personalization/feed',
        queryParameters: {
          'lat': lat,
          'lng': lng,
        },
        options: Options(
          headers: {
            'X-User-Latitude': lat.toString(),
            'X-User-Longitude': lng.toString(),
          },
        ),
      );

      final data = response.data;
      if (data != null && data['success'] == true) {
        final items =
            data['data'] is List ? List<dynamic>.from(data['data']) : <dynamic>[];
        if (!mounted) return;
        setState(() {
          _greeting = data['greeting'] ?? _greeting;
          _timeOfDay = data['timeOfDay'] ?? _timeOfDay;
          _preferredCategory = data['preferredCategory'] ?? _preferredCategory;
          _recommendations = items;
          _locationRequired = data['locationRequired'] == true;
          _emptyMessage = data['message'] as String?;
          _loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Failed to load personalized content.';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to reach server. Please check connection.';
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
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: _FeedTok.textMedium, fontSize: 14),
                  ),
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
                        if (!_locationRequired && _recommendations.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.near_me_rounded, color: _FeedTok.primary, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Near you · $_preferredCategory',
                                  style: const TextStyle(
                                    color: _FeedTok.textHigh,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_recommendations.isEmpty)
                          _EmptyNearbyState(
                            locationRequired: _locationRequired,
                            message: _emptyMessage,
                            onRetry: _loadPersonalizedFeed,
                            onOpenSettings: () => Geolocator.openAppSettings(),
                          )
                        else
                          ..._recommendations.map(
                            (item) => AiFeedCard(
                              item: Map<String, dynamic>.from(item as Map),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _EmptyNearbyState extends StatelessWidget {
  final bool locationRequired;
  final String? message;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  const _EmptyNearbyState({
    required this.locationRequired,
    required this.message,
    required this.onRetry,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _FeedTok.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _FeedTok.border),
      ),
      child: Column(
        children: [
          Icon(
            locationRequired ? Icons.location_off_rounded : Icons.storefront_outlined,
            color: _FeedTok.primary,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            message ??
                (locationRequired
                    ? 'Enable location to see nearby recommendations.'
                    : 'No businesses found near your location right now.'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: _FeedTok.textMedium, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          if (locationRequired) ...[
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.my_location_rounded, size: 18),
              label: const Text('Enable location'),
              style: TextButton.styleFrom(foregroundColor: _FeedTok.primary),
            ),
            TextButton(
              onPressed: onOpenSettings,
              child: const Text(
                'Open settings',
                style: TextStyle(color: _FeedTok.textMedium, fontSize: 12),
              ),
            ),
          ] else
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
              style: TextButton.styleFrom(foregroundColor: _FeedTok.primary),
            ),
        ],
      ),
    );
  }
}
