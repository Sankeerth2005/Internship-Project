import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../core/audio/voice_session_lifecycle.dart';

class VoiceSearchDialog extends ConsumerStatefulWidget {
  const VoiceSearchDialog({super.key});

  @override
  ConsumerState<VoiceSearchDialog> createState() => _VoiceSearchDialogState();
}

class _VoiceSearchDialogState extends ConsumerState<VoiceSearchDialog>
    with SingleTickerProviderStateMixin, VoiceSessionLifecycleMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isListening = false;
  String _statusText = 'Initializing speech...';
  String _voiceOutput = '';

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechEnabled = false;
  bool _hasPopped = false;
  bool _stopping = false;
  Timer? _popTimer;

  final List<String> _voiceShortcuts = [
    'Find pizza open now',
    'Recommend a pharmacy nearby',
    'Artisanal coffee cafes',
    'Best doctors near me',
  ];

  @override
  void initState() {
    super.initState();
    startVoiceLifecycleWatch();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _speechEnabled = await _speech.initialize(
        onError: (val) {
          debugPrint('Speech error: $val');
          if (!mounted) return;
          setState(() {
            _statusText = 'Error: ${val.errorMsg}';
            _isListening = false;
            _pulseController.stop();
          });
        },
        onStatus: (val) {
          debugPrint('Speech status: $val');
          if (val == 'notListening' && _isListening) {
            _stopListening();
          }
        },
      );
      if (!mounted) return;
      setState(() {
        _statusText = _speechEnabled
            ? 'Tap mic to start speaking...'
            : 'Speech recognition not available';
      });
    } catch (e) {
      debugPrint('Speech init failed: $e');
      if (!mounted) return;
      setState(() {
        _statusText = 'Speech recognition failed to load';
      });
    }
  }

  @override
  Future<void> stopActiveVoiceSession() async {
    if (_stopping) return;
    _stopping = true;
    _popTimer?.cancel();
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
      await _speech.cancel();
    } catch (_) {}
    if (_pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
    if (mounted && _isListening) {
      setState(() {
        _isListening = false;
        _statusText = 'Listening stopped.';
      });
    } else {
      _isListening = false;
    }
    _stopping = false;
  }

  Future<void> _closeDialog([String? result]) async {
    if (_hasPopped) return;
    _hasPopped = true;
    await stopActiveVoiceSession();
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  @override
  void dispose() {
    _popTimer?.cancel();
    stopVoiceLifecycleWatch();
    // Best-effort sync stop; async cleanup already requested on close/lifecycle.
    try {
      _speech.stop();
      _speech.cancel();
    } catch (_) {}
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening(cancelled: true);
    } else {
      _startListening();
    }
  }

  Future<void> _startListening() async {
    if (!_speechEnabled) {
      await _initSpeech();
    }
    if (!_speechEnabled || !mounted) {
      if (mounted) {
        setState(() {
          _statusText = 'Mic permission denied or not available.';
        });
      }
      return;
    }

    setState(() {
      _isListening = true;
      _statusText = 'Listening...';
      _voiceOutput = '';
    });
    _pulseController.repeat();

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _voiceOutput = result.recognizedWords;
        });
        if (result.finalResult) {
          _stopListening(query: result.recognizedWords);
        }
      },
    );
  }

  Future<void> _stopListening({String? query, bool cancelled = false}) async {
    try {
      await _speech.stop();
    } catch (_) {}
    if (_pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }

    if (!mounted) return;

    if (cancelled) {
      setState(() {
        _isListening = false;
        _statusText = 'Cancelled. Tap mic to try again.';
      });
      return;
    }

    final finalQuery = query ?? _voiceOutput;
    setState(() {
      _isListening = false;
      _statusText = finalQuery.isNotEmpty
          ? 'Speech processed successfully!'
          : 'Tap mic to start speaking...';
    });

    if (finalQuery.isNotEmpty) {
      _popTimer?.cancel();
      _popTimer = Timer(const Duration(milliseconds: 800), () {
        _closeDialog(finalQuery);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 30),
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFF7A00).withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Color(0xFFFF7A00), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'AI Voice Search',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, color: Colors.white30, size: 20),
                  onPressed: () => _closeDialog(),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Center(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_isListening)
                        Container(
                          width: 80 * _pulseAnimation.value,
                          height: 80 * _pulseAnimation.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFF7A00).withValues(alpha:
                              (1.8 - _pulseAnimation.value).clamp(0.0, 1.0),
                            ),
                          ),
                        ),
                      GestureDetector(
                        onTap: _toggleListening,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isListening
                                ? const Color(0xFFFF7A00)
                                : const Color(0xFF2E2E2E),
                            border: Border.all(
                              color: const Color(0xFFFF7A00).withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: _isListening ? Colors.black : const Color(0xFFFF7A00),
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _statusText,
              style: TextStyle(
                color: _isListening ? const Color(0xFFFF7A00) : Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (_voiceOutput.isNotEmpty) ...[
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '"$_voiceOutput"',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 25),
            const Divider(color: Colors.white10),
            const SizedBox(height: 15),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Try asking...',
                style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _voiceShortcuts.map((shortcut) {
                return GestureDetector(
                  onTap: () {
                    if (!_hasPopped) {
                      _stopListening(query: shortcut);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.subdirectory_arrow_right, color: Color(0xFFFF7A00), size: 12),
                        const SizedBox(width: 4),
                        Text(
                          shortcut,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
