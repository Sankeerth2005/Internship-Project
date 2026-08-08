import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../models/chat_models.dart';

/// REST chat endpoints — Bearer injected by [DioClient]. SignalR stays in ChatNotifier.
class ChatRepository {
  final Dio _dio;

  ChatRepository({required Dio dio}) : _dio = dio;

  Future<List<Conversation>> getUserConversations() async {
    final response = await _dio.get('chat/user');
    final list = response.data as List? ?? [];
    return list
        .map((c) => Conversation.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<List<Conversation>> getBusinessConversations(int businessId) async {
    final response = await _dio.get('chat/business/$businessId');
    final list = response.data as List? ?? [];
    return list
        .map((c) => Conversation.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatMessage>> getMessages(int conversationId) async {
    final response = await _dio.get('chat/messages/$conversationId');
    final list = response.data as List? ?? [];
    return list
        .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<void> sendVoice(int conversationId, FormData formData) async {
    await _dio.post('chat/voice/$conversationId', data: formData);
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(dio: DioClient().dio);
});
