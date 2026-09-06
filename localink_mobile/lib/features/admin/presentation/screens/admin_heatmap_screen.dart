import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../../../core/network/dio_client.dart';

class AdminHeatmapScreen extends ConsumerStatefulWidget {
  const AdminHeatmapScreen({super.key});

  @override
  ConsumerState<AdminHeatmapScreen> createState() => _AdminHeatmapScreenState();
}

class _AdminHeatmapScreenState extends ConsumerState<AdminHeatmapScreen> {
  MapLibreMapController? _mapController;
  bool _loading = true;
  List<dynamic> _businesses = [];
  List<dynamic> _searches = [];
  String _errorMessage = "";
  LatLng? _mapCenter;
  double _mapZoom = 3;

  // OpenStreetMap styles vector tiles
  final String osmStyle = "https://tiles.openfreemap.org/styles/liberty";

  @override
  void initState() {
    super.initState();
    _loadHeatmapData();
  }

  List<LatLng> _collectValidPoints() {
    final points = <LatLng>[];

    void addPoint(dynamic latRaw, dynamic lngRaw) {
      final lat = double.tryParse(latRaw?.toString() ?? '');
      final lng = double.tryParse(lngRaw?.toString() ?? '');
      if (lat == null || lng == null) return;
      if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return;
      if (lat == 0 && lng == 0) return;
      points.add(LatLng(lat, lng));
    }

    for (final b in _businesses) {
      addPoint(b['latitude'], b['longitude']);
    }
    for (final s in _searches) {
      addPoint(s['latitude'], s['longitude']);
    }
    return points;
  }

  /// Derive camera from real data only — never invent a city fallback.
  void _deriveCameraFromData() {
    final points = _collectValidPoints();
    if (points.isEmpty) {
      _mapCenter = null;
      return;
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final p in points.skip(1)) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    _mapCenter = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    final latSpan = (maxLat - minLat).abs();
    final lngSpan = (maxLng - minLng).abs();
    final span = latSpan > lngSpan ? latSpan : lngSpan;
    if (span < 0.05) {
      _mapZoom = 12;
    } else if (span < 0.5) {
      _mapZoom = 10;
    } else if (span < 2) {
      _mapZoom = 8;
    } else if (span < 10) {
      _mapZoom = 6;
    } else {
      _mapZoom = 4;
    }
  }

  Future<void> _loadHeatmapData() async {
    setState(() {
      _loading = true;
      _errorMessage = "";
    });

    try {
      final response = await DioClient().dio.get('analytics/heatmap');
      final data = response.data;
      if (data != null && data['success'] == true) {
        setState(() {
          _businesses = data['businesses'] ?? [];
          _searches = data['searches'] ?? [];
          _deriveCameraFromData();
          _loading = false;
        });
        _addHeatmapPoints();
        _moveCameraToData();
      } else {
        setState(() {
          _errorMessage = "Failed to load heatmap data.";
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Unable to connect to metrics server.";
        _loading = false;
      });
    }
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
    _addHeatmapPoints();
    _moveCameraToData();
  }

  Future<void> _moveCameraToData() async {
    final center = _mapCenter;
    final controller = _mapController;
    if (center == null || controller == null) return;
    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: center, zoom: _mapZoom),
        ),
      );
    } catch (_) {
      // Map may not be ready yet; symbols still render.
    }
  }

  void _addHeatmapPoints() {
    if (_mapController == null || _loading) return;

    _mapController!.clearSymbols();

    for (var b in _businesses) {
      final lat = double.tryParse(b['latitude']?.toString() ?? '');
      final lng = double.tryParse(b['longitude']?.toString() ?? '');
      if (lat == null || lng == null) continue;
      if (lat < -90 || lat > 90 || lng < -180 || lng > 180) continue;
      if (lat == 0 && lng == 0) continue;

      _mapController!.addSymbol(
        SymbolOptions(
          geometry: LatLng(lat, lng),
          iconImage: "marker",
          iconSize: 1.2,
          textField: b['businessName'] ?? '',
          textOffset: const Offset(0, 2),
          textColor: "#FF7A00",
          textSize: 10,
        ),
      );
    }

    for (var s in _searches) {
      final lat = double.tryParse(s['latitude']?.toString() ?? '');
      final lng = double.tryParse(s['longitude']?.toString() ?? '');
      if (lat == null || lng == null) continue;
      if (lat < -90 || lat > 90 || lng < -180 || lng > 180) continue;
      if (lat == 0 && lng == 0) continue;

      _mapController!.addSymbol(
        SymbolOptions(
          geometry: LatLng(lat, lng),
          iconSize: 0.8,
          textField: "🔍 ${s['query']}",
          textOffset: const Offset(0, -2),
          textColor: "#FF5252",
          textSize: 9,
        ),
      );
    }
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Heatmap Analytics',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            Text(
              'Operations Center',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFFFF7A00),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFF7A00)),
            onPressed: _loadHeatmapData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withValues(alpha: 0.05),
            height: 1,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A00)))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(_errorMessage, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                )
              : _mapCenter == null
                  ? const Center(
                      child: Text(
                        'No valid business or search coordinates to display.',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Stack(
                      children: [
                        Positioned.fill(
                          child: MapLibreMap(
                            styleString: osmStyle,
                            initialCameraPosition: CameraPosition(
                              target: _mapCenter!,
                              zoom: _mapZoom,
                            ),
                            onMapCreated: _onMapCreated,
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          left: 15,
                          right: 15,
                          child: Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161616).withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'OPERATIONAL LEGEND',
                                  style: TextStyle(
                                    color: Color(0xFFFF7A00),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF7A00),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Approved Businesses (${_businesses.length})',
                                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                    const SizedBox(width: 20),
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: const BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Active Search Queries (${_searches.length})',
                                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Visual density markers display registered companies vs areas where customers query items most, helping identify underserved regions.',
                                  style: TextStyle(color: Colors.white30, fontSize: 9, height: 1.4),
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
