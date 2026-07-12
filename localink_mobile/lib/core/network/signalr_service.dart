import 'package:flutter/material.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dio_client.dart';
import '../../main.dart';

class SignalRService {
  HubConnection? _hubConnection;
  
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;
  SignalRService._internal();

  bool get isConnected => _hubConnection?.state == HubConnectionState.Connected;

  Future<void> connect(int userId, String role, BuildContext context) async {
    if (_hubConnection != null && _hubConnection!.state == HubConnectionState.Connected) {
      return;
    }

    String url = 'https://8c24-49-206-52-240.ngrok-free.app/notifications';

    _hubConnection = HubConnectionBuilder().withUrl(url).build();

    _hubConnection!.onclose(({error}) {
      debugPrint('SignalR: Connection closed. Error: $error');
    });

    _hubConnection!.on('ReceiveNotification', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final message = arguments[0] as String;
        debugPrint('SignalR Notification: $message');
        
        // Show real-time SnackBar using global scaffoldMessengerState
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_active, color: Color(0xFFC8A97E)),
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

  Future<void> disconnect(int userId) async {
    if (_hubConnection != null && _hubConnection!.state == HubConnectionState.Connected) {
      try {
        await _hubConnection!.invoke('LeaveGroup', args: ['client_$userId']);
        await _hubConnection!.stop();
        _hubConnection = null;
        debugPrint('SignalR: Disconnected');
      } catch (e) {
        debugPrint('SignalR disconnect error: $e');
      }
    }
  }
}
