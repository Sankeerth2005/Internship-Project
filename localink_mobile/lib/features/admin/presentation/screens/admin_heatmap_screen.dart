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

  // OpenStreetMap styles vector tiles
  final String osmStyle = "https://tiles.openfreemap.org/styles/liberty";

  @override
  void initState() {
    super.initState();
    _loadHeatmapData();
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
          _loading = false;
        });
        _addHeatmapPoints();
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
  }

  void _addHeatmapPoints() {
    if (_mapController == null || _loading) return;

    _mapController!.clearSymbols();

    // 1. Add gold pins for approved businesses
    for (var b in _businesses) {
      double lat = double.tryParse(b['latitude']?.toString() ?? '') ?? 19.0760;
      double lng = double.tryParse(b['longitude']?.toString() ?? '') ?? 72.8777;

      _mapController!.addSymbol(
        SymbolOptions(
          geometry: LatLng(lat, lng),
          iconImage: "custom-marker-gold", // Custom assets fallback
          iconSize: 1.2,
          textField: b['businessName'] ?? '',
          textOffset: const Offset(0, 2),
          textColor: "#C8A97E",
          textSize: 10,
        ),
      );
    }

    // 2. Add red pulsing radar pins for search query logs
    for (var s in _searches) {
      double lat = double.tryParse(s['latitude']?.toString() ?? '') ?? 19.0760;
      double lng = double.tryParse(s['longitude']?.toString() ?? '') ?? 72.8777;

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
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Heatmap Analytics',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Operations Center',
              style: TextStyle(color: Color(0xFFC8A97E), fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFC8A97E)),
            onPressed: _loadHeatmapData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC8A97E)))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(_errorMessage, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                )
              : Stack(
                  children: [
                    // Fullscreen Vector Map
                    Positioned.fill(
                      child: MapLibreMap(
                        styleString: osmStyle,
                        initialCameraPosition: const CameraPosition(
                          target: LatLng(19.0760, 72.8777), // Center map in Mumbai/India
                          zoom: 11,
                        ),
                        onMapCreated: _onMapCreated,
                      ),
                    ),

                    // Map Legends Overlay
                    Positioned(
                      bottom: 20,
                      left: 15,
                      right: 15,
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'OPERATIONAL LEGEND',
                              style: TextStyle(color: Color(0xFFC8A97E), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(color: Color(0xFFC8A97E), shape: BoxShape.circle),
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
                                  decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
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
