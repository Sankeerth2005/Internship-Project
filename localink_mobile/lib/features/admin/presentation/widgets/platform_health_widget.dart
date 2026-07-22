import 'package:flutter/material.dart';
import '../../../../core/network/signalr_service.dart';

class PlatformHealthWidget extends StatefulWidget {
  const PlatformHealthWidget({super.key});

  @override
  State<PlatformHealthWidget> createState() => _PlatformHealthWidgetState();
}

class _PlatformHealthWidgetState extends State<PlatformHealthWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSignalRActive = SignalRService().isConnected;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.analytics_outlined, color: Color(0xFFFF7A00), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Platform Health',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Score: 99%',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 16),
          _buildHealthRow('Server Core', 'Online', Colors.green, true),
          const SizedBox(height: 12),
          _buildHealthRow('Main Database', 'Connected', Colors.green, true),
          const SizedBox(height: 12),
          _buildHealthRow('API Gateway', 'Active', Colors.green, true),
          const SizedBox(height: 12),
          _buildHealthRow(
            'SignalR Service',
            isSignalRActive ? 'Connected' : 'Disconnected',
            isSignalRActive ? Colors.green : Colors.amber,
            isSignalRActive,
          ),
          const SizedBox(height: 12),
          _buildHealthRow('Job Dispatcher', 'Idle', Colors.green, true),
        ],
      ),
    );
  }

  Widget _buildHealthRow(String service, String status, Color color, bool healthy) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: healthy
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 4 + _pulseController.value * 6,
                              spreadRadius: _pulseController.value * 2,
                            ),
                          ]
                        : null,
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Text(
              service,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Text(
          status,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
