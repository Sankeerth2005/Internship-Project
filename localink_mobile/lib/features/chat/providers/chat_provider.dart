import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:dio/dio.dart';
import 'dart:io';

import '../../auth/providers/auth_provider.dart';
import '../../../core/network/dio_client.dart';

// Represents a conversation
class Conversation {
  final int id;
  final int? businessId;
  final String? businessName;
  final String? businessImage;
  final int? userId;
  final String? userName;
  final DateTime lastMessageAt;

  Conversation({
    required this.id,
    this.businessId,
    this.businessName,
    this.businessImage,
    this.userId,
    this.userName,
    required this.lastMessageAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      businessId: json['businessId'],
      businessName: json['businessName'],
      businessImage: json['businessImage'],
      userId: json['userId'],
      userName: json['userName'],
      lastMessageAt: DateTime.parse(json['lastMessageAt']),
    );
  }
}

// Represents a single message
class ChatMessage {
  final int id;
  final String senderRole;
  final String? text;
  final String? audioUrl;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderRole,
    this.text,
    this.audioUrl,
    required this.timestamp,
    required this.isRead,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      senderRole: json['senderRole'],
      text: json['text'],
      audioUrl: json['audioUrl'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'],
    );
  }
}

// Chat State
class ChatState {
  final bool isLoading;
  final List<Conversation> conversations;
  final List<ChatMessage> currentMessages;
  final HubConnection? hubConnection;

  ChatState({
    this.isLoading = false,
    this.conversations = const [],
    this.currentMessages = const [],
    this.hubConnection,
  });

  ChatState copyWith({
    bool? isLoading,
    List<Conversation>? conversations,
    List<ChatMessage>? currentMessages,
    HubConnection? hubConnection,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      conversations: conversations ?? this.conversations,
      currentMessages: currentMessages ?? this.currentMessages,
      hubConnection: hubConnection ?? this.hubConnection,
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  late DioClient _dioClient;
  late String _token;

  @override
  ChatState build() {
    _dioClient = DioClient();
    final authState = ref.watch(authProvider);
    _token = (authState as dynamic).token ?? '';
    
    ref.onDispose(() {
      state.hubConnection?.stop();
    });
    
    _initSignalR();
    return ChatState();
  }

  Future<void> _initSignalR() async {
    final hubConnection = HubConnectionBuilder()
        .withUrl(
          'http://10.0.2.2:5138/chat',
          options: HttpConnectionOptions(
            accessTokenFactory: () async => _token,
          ),
        )
        .withAutomaticReconnect()
        .build();

    hubConnection.on('ReceiveMessage', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final rawMsg = arguments.first as Map<String, dynamic>;
        final newMsg = ChatMessage.fromJson(rawMsg);
        state = state.copyWith(
          currentMessages: [...state.currentMessages, newMsg],
        );
      }
    });

    try {
      await hubConnection.start();
      state = state.copyWith(hubConnection: hubConnection);
    } catch (e) {
      // ignore
    }
  }

  Future<void> loadUserConversations() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _dioClient.dio.get('chat/user');
      final list = (response.data as List).map((c) => Conversation.fromJson(c)).toList();
      state = state.copyWith(conversations: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadMessages(int conversationId) async {
    try {
      final response = await _dioClient.dio.get('chat/messages/$conversationId');
      final msgs = (response.data as List).map((m) => ChatMessage.fromJson(m)).toList();
      state = state.copyWith(currentMessages: msgs);

      // Join SignalR group
      if (state.hubConnection?.state == HubConnectionState.Connected) {
        await state.hubConnection?.invoke('JoinConversation', args: [conversationId]);
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> sendTextMessage(int conversationId, String role, String text) async {
    if (state.hubConnection?.state == HubConnectionState.Connected) {
      await state.hubConnection?.invoke('SendMessage', args: [conversationId, role, text]);
    }
  }

  Future<void> sendVoiceMessage(int conversationId, String role, String filePath) async {
    try {
      FormData formData = FormData.fromMap({
        'role': role,
        'file': await MultipartFile.fromFile(filePath),
      });
      await _dioClient.dio.post('chat/voice/$conversationId', data: formData);
    } catch (e) {
      // ignore
    }
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(() {
  return ChatNotifier();
});
