import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';

/// AI voice/search endpoints — Bearer injected by [DioClient].
class AiRepository {
  final Dio _dio;

  AiRepository({required Dio dio}) : _dio = dio; // ignore: prefer_initializing_formals

  Future<String?> transcribe(FormData formData) async {
    final response = await _dio.post('ai/transcribe', data: formData);
    final data = response.data;
    if (data is Map) {
      final text = data['data']?.toString();
      if (text != null && text.trim().isNotEmpty) return text.trim();
    }
    return null;
  }

  Future<String> chatSearch({
    required String message,
    required String chatHistoryJson,
  }) async {
    final response = await _dio.post(
      'ai/chat-search',
      data: {
        'message': message,
        'chatHistoryJson': chatHistoryJson,
      },
    );
    final data = response.data;
    if (data is Map) {
      return data['data']?.toString() ??
          'I am having trouble answering right now. Please try again.';
    }
    return 'I am having trouble answering right now. Please try again.';
  }
}

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepository(dio: DioClient().dio);
});
