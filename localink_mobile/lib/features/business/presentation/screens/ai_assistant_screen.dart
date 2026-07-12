import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final List<Map<String, String>> _messages = [
    {
      'role': 'assistant',
      'content': 'Namaste! I am your Vocal for Sanatan AI Guide. Ask me anything about our registered local businesses, services, or recommendations!'
    }
  ];
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final query = _textController.text.trim();
    if (query.isEmpty) return;

    _textController.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': query});
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      // Keep only the last 10 messages for token context efficiency
      final recentHistory = _messages.length > 10 
          ? _messages.sublist(_messages.length - 10) 
          : _messages;
      
      final historyJson = jsonEncode(recentHistory);

      final response = await DioClient().dio.post(
        'ai/chat-search',
        data: {
          'message': query,
          'chatHistoryJson': historyJson,
        },
      );

      final reply = response.data['data'] as String? ?? 'I am having trouble answering right now. Please try again.';
      setState(() {
        _messages.add({'role': 'assistant', 'content': reply});
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'Sorry, I couldn\'t connect to the server. Please verify your connection.'
        });
        _isLoading = false;
      });
    }
    _scrollToBottom();
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
              'AI Search Guide',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Llama Powered',
              style: TextStyle(color: Color(0xFFC8A97E), fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(15),
              itemCount: _messages.length,
              itemBuilder: (context, idx) {
                final msg = _messages[idx];
                final isUser = msg['role'] == 'user';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isUser) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC8A97E).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.auto_awesome, color: Color(0xFFC8A97E), size: 16),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isUser ? const Color(0xFFC8A97E) : const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                              bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                            ),
                            border: isUser 
                                ? null 
                                : Border.all(color: Colors.white12),
                          ),
                          child: Text(
                            msg['content'] ?? '',
                            style: TextStyle(
                              color: isUser ? Colors.black : Colors.white,
                              fontSize: 13,
                              height: 1.4,
                              fontWeight: isUser ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, color: Colors.white70, size: 16),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFC8A97E)),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'AI Guide is typing...',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                    )
                  ],
                ),
              ),
            ),
          // Text Input Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            color: const Color(0xFF1E1E1E),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Search or ask for recommendations...',
                        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                        filled: true,
                        fillColor: Colors.black26,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFC8A97E),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.black, size: 18),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
