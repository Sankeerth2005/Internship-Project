import 'package:flutter/material.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'dio_client.dart';
import '../../main.dart';

class SignalRService {
  HubConnection? _hubConnection;
  final List<Function(String)> _notificationListeners = [];
  
  String? _lastNotificationMessage;
  DateTime? _lastNotificationTime;

  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;
  SignalRService._internal();

  bool get isConnected => _hubConnection?.state == HubConnectionState.Connected;

  void addNotificationListener(Function(String) listener) {
    if (!_notificationListeners.contains(listener)) {
      _notificationListeners.add(listener);
    }
  }

  void removeNotificationListener(Function(String) listener) {
    _notificationListeners.remove(listener);
  }

  void clearNotificationListeners() {
    _notificationListeners.clear();
  }

  Future<void> connect(int userId, String role, BuildContext context) async {
    if (_hubConnection != null && 
        (_hubConnection!.state == HubConnectionState.Connected || 
         _hubConnection!.state == HubConnectionState.Connecting)) {
      return;
    }

    final baseUrl = DioClient().dio.options.baseUrl;
    final url = baseUrl.replaceAll('/api/v1/', '/notifications');

    _hubConnection = HubConnectionBuilder().withUrl(url).build();

    _hubConnection!.onclose(({error}) {
      debugPrint('SignalR: Connection closed. Error: $error');
    });

    _hubConnection!.on('ReceiveNotification', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final message = arguments[0] as String;

        // Deduplicate notifications received within 3 seconds
        final now = DateTime.now();
        if (_lastNotificationMessage == message &&
            _lastNotificationTime != null &&
            now.difference(_lastNotificationTime!) < const Duration(seconds: 3)) {
          debugPrint('SignalR Notification (Duplicate Ignored): $message');
          return;
        }

        _lastNotificationMessage = message;
        _lastNotificationTime = now;
        debugPrint('SignalR Notification: $message');

        // Notify all registered listeners (take a snapshot copy to prevent concurrent modification)
        final listenersSnapshot = List<Function(String)>.from(_notificationListeners);
        for (final listener in listenersSnapshot) {
          try {
            listener(message);
          } catch (e) {
            debugPrint('Error invoking notification listener: $e');
          }
        }
        
        // Show real-time SnackBar using global scaffoldMessengerState (clear existing first)
        scaffoldMessengerKey.currentState?.clearSnackBars();
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_active, color: Color(0xFFFF7A00)),
                const SizedBox(width: 10),
                Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 13))),
              ],
            ),
            backgroundColor: const Color(0xFF1E1E1E),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    });

    try {
      await _hubConnection!.start();
      debugPrint('SignalR: Connected to hub!');
      
      // Join user specific group
      await _hubConnection!.invoke('JoinGroup', args: ['client_$userId']);
      debugPrint('SignalR: Joined group client_$userId');

      if (role.toLowerCase().trim() == 'admin') {
        await _hubConnection!.invoke('JoinGroup', args: ['admin']);
        debugPrint('SignalR: Joined group admin');
      }
    } catch (e) {
      debugPrint('SignalR connection failed: $e');
    }
  }

  Future<void> disconnect([int? userId]) async {
    _notificationListeners.clear();
    _lastNotificationMessage = null;
    _lastNotificationTime = null;
    scaffoldMessengerKey.currentState?.clearSnackBars();

    if (_hubConnection != null) {
      try {
        if (userId != null && _hubConnection!.state == HubConnectionState.Connected) {
          await _hubConnection!.invoke('LeaveGroup', args: ['client_$userId']);
        }
        await _hubConnection!.stop();
        debugPrint('SignalR: Disconnected');
      } catch (e) {
        debugPrint('SignalR disconnect error: $e');
      } finally {
        _hubConnection = null;
      }
    }
  }
}
