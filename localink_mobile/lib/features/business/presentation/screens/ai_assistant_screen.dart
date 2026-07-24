import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../shared/presentation/widgets/app_back_button.dart';
import '../../../ai/widgets/ai_message_bubble.dart';
import '../../../ai/widgets/ai_prompt_chips.dart';

// ─── DESIGN TOKENS ────────────────────────────────────────────────────────────
class _AiTok {
  static const Color primary = Color(0xFFFF6600);
  static const Color bg = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFF9F8F6);
  static const Color border = Color(0xFFEAE8E3);
  static const Color textHigh = Color(0xFF1A1918);
  static const Color textLow = Color(0xFF9F9B96);
}

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

  final List<String> _suggestedPrompts = [
    'Best handcraft shops',
    'Pure vegetarian restaurants',
    'Temples to visit nearby',
    'Top rated local services',
  ];

  final AudioRecorder _audioRecorder = AudioRecorder();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-IN");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> _toggleRecording() async {
    try {
      if (await _audioRecorder.isRecording()) {
        final path = await _audioRecorder.stop();
        setState(() => _isRecording = false);
        if (path != null) {
          _transcribeAudio(path);
        }
      } else {
        if (await Permission.microphone.request().isGranted) {
          final dir = await getTemporaryDirectory();
          final path = '${dir.path}/ai_voice_query_${DateTime.now().millisecondsSinceEpoch}.m4a';
          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.aacLc, numChannels: 1, sampleRate: 44100),
            path: path,
          );
          setState(() => _isRecording = true);
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission is required.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Recording error: $e');
      setState(() => _isRecording = false);
    }
  }

  Future<void> _transcribeAudio(String path) async {
    setState(() => _isLoading = true);
    try {
      final file = File(path);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: 'voice_query.m4a'),
      });

      final response = await DioClient().dio.post('ai/transcribe', data: formData);
      final text = response.data['data'] as String?;
      
      if (text != null && text.trim().isNotEmpty) {
        _textController.text = text.trim();
        _sendMessage();
      } else {
        setState(() => _isLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not transcribe audio. Please try again.')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Transcription error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transcription failed. Check connection.')),
      );
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _audioRecorder.dispose();
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

  Future<void> _sendMessage([String? customText]) async {
    final query = (customText ?? _textController.text).trim();
    if (query.isEmpty) return;

    if (customText == null) {
      _textController.clear();
    }

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
      _speak(reply);
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
    final showSuggestions = _messages.length == 1 && !_isLoading;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/home');
      },
      child: Scaffold(
        backgroundColor: _AiTok.bg,
        appBar: AppBar(
          backgroundColor: _AiTok.bg,
          elevation: 0,
          leadingWidth: 70,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
            child: AppBackButton(onPressed: () => context.go('/home')),
          ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Search Guide',
              style: TextStyle(color: _AiTok.textHigh, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Llama Powered',
              style: TextStyle(color: _AiTok.primary, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: _AiTok.border,
            height: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, idx) {
                final msg = _messages[idx];
                final isUser = msg['role'] == 'user';
                return AiMessageBubble(
                  content: msg['content'] ?? '',
                  isUser: isUser,
                );
              },
            ),
          ),
          if (showSuggestions)
            AiPromptChips(
              prompts: _suggestedPrompts,
              onSelect: (prompt) => _sendMessage(prompt),
            ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _AiTok.primary),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'AI Guide is typing...',
                      style: TextStyle(color: _AiTok.textLow, fontSize: 11),
                    )
                  ],
                ),
              ),
            ),
          // Text Input Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: _AiTok.bg,
              border: Border(
                top: BorderSide(color: _AiTok.border),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: _AiTok.textHigh, fontSize: 14),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: _isRecording ? 'Listening...' : 'Search or ask for recommendations...',
                        hintStyle: const TextStyle(color: _AiTok.textLow, fontSize: 13),
                        filled: true,
                        fillColor: _isRecording ? const Color(0xFFFFF2EC) : _AiTok.cardBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: _AiTok.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: _AiTok.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: _AiTok.primary, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _toggleRecording,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isRecording ? Colors.red : _AiTok.cardBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: _isRecording ? Colors.red : _AiTok.border),
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop_rounded : Icons.mic_none_rounded,
                        color: _isRecording ? Colors.white : _AiTok.primary,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendMessage(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: _AiTok.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    ),);
  }
}
