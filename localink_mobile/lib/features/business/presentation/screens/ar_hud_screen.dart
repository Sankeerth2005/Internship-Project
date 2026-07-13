import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';

class ArHudScreen extends StatefulWidget {
  const ArHudScreen({super.key});

  @override
  State<ArHudScreen> createState() => _ArHudScreenState();
}

class _ArHudScreenState extends State<ArHudScreen> {
  CameraController? _cameraController;
  bool _cameraInitialized = false;
  Position? _currentPosition;
  double _heading = 0.0; // Heading in degrees (0-360)
  List<dynamic> _nearbyBusinesses = [];
  bool _loading = true;
  String _errorMsg = "";

  StreamSubscription? _sensorsSubscription;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeLocationAndSensors();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _sensorsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _errorMsg = "No camera found on device.";
        });
        return;
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _cameraInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Fall back gracefully to radar view simulation if camera permission denied
          _cameraInitialized = false;
        });
      }
    }
  }

  Future<void> _initializeLocationAndSensors() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = pos;
      });

      // Load nearby businesses
      await _loadNearbyBusinesses(pos.latitude, pos.longitude);

      // Track device heading/rotation using Magnetometer
      _sensorsSubscription = magnetometerEvents.listen((MagnetometerEvent event) {
        if (!mounted) return;
        // Basic calculation of compass heading from magnetic vector field
        double headingRad = atan2(event.y, event.x);
        double headingDeg = headingRad * (180 / pi);
        // Normalize to 0-360
        if (headingDeg < 0) headingDeg += 360;

        setState(() {
          _heading = headingDeg;
        });
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = "Location permissions or sensors required.";
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadNearbyBusinesses(double lat, double lng) async {
    try {
      final response = await DioClient().dio.get(
        'business/search',
        queryParameters: {'query': ''},
      );
      final data = response.data;
      if (data != null && data is List) {
        setState(() {
          _nearbyBusinesses = data;
          _loading = false;
        });
      } else {
        setState(() {
          _nearbyBusinesses = [];
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _loading = false;
      });
    }
  }

  // Bearing calculation from user location to business
  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    double dLon = (lon2 - lon1) * pi / 180;
    double rLat1 = lat1 * pi / 180;
    double rLat2 = lat2 * pi / 180;

    double y = sin(dLon) * cos(rLat2);
    double x = cos(rLat1) * sin(rLat2) - sin(rLat1) * cos(rLat2) * cos(dLon);

    double brng = atan2(y, x) * 180 / pi;
    return (brng + 360) % 360;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFFC8A97E)),
              SizedBox(height: 15),
              Text('Booting AR Hud Engine...', style: TextStyle(color: Color(0xFFC8A97E))),
            ],
          ),
        ),
      );
    }

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Live Camera Feed Backdrop
          if (_cameraInitialized && _cameraController != null)
            Positioned.fill(
              child: AspectRatio(
                aspectRatio: _cameraController!.value.aspectRatio,
                child: CameraPreview(_cameraController!),
              ),
            )
          else
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    colors: [Color(0xFF1E1408), Colors.black],
                    radius: 1.0,
                  ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.radar, color: Color(0xFFC8A97E), size: 60),
                      SizedBox(height: 10),
                      Text('PSEUDO RADAR MODE ACTIVE', style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 2)),
                    ],
                  ),
                ),
              ),
            ),

          // Dark overlay tint for readability of cards
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.3)),
          ),

          // 2. Fullscreen HUD overlays
          Positioned.fill(
            child: Stack(
              children: _nearbyBusinesses.map((item) {
                // Parse coordinates safely
                double busLat = double.tryParse(item['latitude']?.toString() ?? '') ?? 0.0;
                double busLng = double.tryParse(item['longitude']?.toString() ?? '') ?? 0.0;

                if (busLat == 0.0 || _currentPosition == null) return const SizedBox.shrink();

                // Calculate distance
                double dist = Geolocator.distanceBetween(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                  busLat,
                  busLng,
                );

                // Calculate bearing
                double bearing = _calculateBearing(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                  busLat,
                  busLng,
                );

                // Calculate relative angle relative to user's compass heading
                double diff = bearing - _heading;
                if (diff < -180) diff += 360;
                if (diff > 180) diff -= 360;

                // Field of view (FOV) is +/- 45 degrees
                if (diff.abs() > 45) return const SizedBox.shrink();

                // Horizontal screen offset (-0.5 to 0.5)
                double xOffset = diff / 90; // Maps -45 to -0.5 and +45 to 0.5
                double xPos = size.width / 2 + (xOffset * size.width);

                // Vertical offset based on distance
                double yPos = size.height / 2 - (dist / 100);
                if (yPos < 100) yPos = 100;
                if (yPos > size.height - 200) yPos = size.height - 200;

                return Positioned(
                  left: xPos - 110,
                  top: yPos,
                  child: Container(
                    width: 220,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC8A97E)),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFFC8A97E).withValues(alpha: 0.15), blurRadius: 10),
                      ],
                    ),
                    child: InkWell(
                      onTap: () => context.push('/business-detail/${item['businessId']}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item['businessName'] ?? '',
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Icon(Icons.star, color: Color(0xFFC8A97E), size: 12),
                              const SizedBox(width: 2),
                              const Text('4.8', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.navigation, color: Color(0xFFC8A97E), size: 10),
                              const SizedBox(width: 4),
                              Text(
                                '${(dist / 1000).toStringAsFixed(1)} km away',
                                style: const TextStyle(color: Color(0xFFC8A97E), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['description'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white38, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // 3. UI Controls Overlay
          Positioned(
            top: 40,
            left: 15,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 15),
                const Text(
                  'AR Street view HUD',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Compass Radar Circle in top-right
          Positioned(
            top: 40,
            right: 15,
            child: Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFC8A97E)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(
                    angle: -_heading * pi / 180,
                    child: const Icon(Icons.navigation, color: Color(0xFFC8A97E), size: 24),
                  ),
                  Positioned(
                    top: 2,
                    child: Text('N', style: TextStyle(color: const Color(0xFFC8A97E), fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Scanning HUD Overlay UI
          Positioned(
            bottom: 25,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.center_focus_weak, color: Color(0xFFC8A97E), size: 16),
                  SizedBox(width: 8),
                  Text(
                    'PAN YOUR PHONE TO DETECT NEARBY LISTINGS',
                    style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2),
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
