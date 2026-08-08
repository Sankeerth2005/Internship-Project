import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../../../core/network/app_error_formatter.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../business/providers/business_provider.dart';
import '../data/models/chat_models.dart';
import '../data/repositories/chat_repository.dart';

export '../data/models/chat_models.dart';

class ChatState {
  final bool isLoading;
  final List<Conversation> conversations;
  final List<ChatMessage> currentMessages;
  final HubConnection? hubConnection;
  final String? error;

  ChatState({
    this.isLoading = false,
    this.conversations = const [],
    this.currentMessages = const [],
    this.hubConnection,
    this.error,
  });

  ChatState copyWith({
    bool? isLoading,
    List<Conversation>? conversations,
    List<ChatMessage>? currentMessages,
    HubConnection? hubConnection,
    String? error,
    bool clearError = false,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      conversations: conversations ?? this.conversations,
      currentMessages: currentMessages ?? this.currentMessages,
      hubConnection: hubConnection ?? this.hubConnection,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  ChatRepository get _repo => ref.read(chatRepositoryProvider);

  @override
  ChatState build() {
    ref.onDispose(() {
      state.hubConnection?.stop();
    });
    Future.microtask(_initSignalR);
    return ChatState();
  }

  Future<String> _token() async =>
      await SecureStorageService.getToken() ?? '';

  Future<void> _initSignalR() async {
    final hubUrl = '${DioClient.backendOrigin}/chat';
    final hubConnection = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: _token,
          ),
        )
        .withAutomaticReconnect()
        .build();

    hubConnection.on('ReceiveMessage', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final rawMsg = Map<String, dynamic>.from(arguments.first as Map);
        final newMsg = ChatMessage.fromJson(rawMsg);
        state = state.copyWith(
          currentMessages: [...state.currentMessages, newMsg],
        );
      }
    });

    try {
      await hubConnection.start();
      state = state.copyWith(hubConnection: hubConnection);
    } catch (_) {
      // Hub optional until chat screen opens
    }
  }

  Future<void> loadUserConversations() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repo.getUserConversations();
      state = state.copyWith(conversations: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: AppErrorFormatter.format(e),
      );
    }
  }

  /// Owner inbox — loads conversations for every business owned by the user.
  Future<void> loadOwnerConversations() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final businesses = await ref.read(myBusinessesProvider.future);
      if (businesses.isEmpty) {
        state = state.copyWith(conversations: [], isLoading: false);
        return;
      }

      final all = <Conversation>[];
      for (final b in businesses) {
        final list = await _repo.getBusinessConversations(b.businessId);
        all.addAll(list);
      }
      all.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      state = state.copyWith(conversations: all, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: AppErrorFormatter.format(e),
      );
    }
  }

  Future<void> loadMessages(int conversationId) async {
    try {
      final msgs = await _repo.getMessages(conversationId);
      state = state.copyWith(currentMessages: msgs);

      if (state.hubConnection?.state == HubConnectionState.Connected) {
        await state.hubConnection
            ?.invoke('JoinConversation', args: [conversationId]);
      }
    } catch (_) {}
  }

  Future<void> sendTextMessage(int conversationId, String role, String text) async {
    if (state.hubConnection?.state == HubConnectionState.Connected) {
      await state.hubConnection
          ?.invoke('SendMessage', args: [conversationId, role, text]);
    }
  }

  Future<void> sendVoiceMessage(int conversationId, String role, String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      await _repo.sendVoice(conversationId, formData);
    } catch (_) {}
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
