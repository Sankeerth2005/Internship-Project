import 'package:flutter/widgets.dart';

/// Watches app lifecycle and stops voice/mic sessions when the app backgrounds.
/// Subclasses must implement [stopActiveVoiceSession] and call it from their own [dispose].
mixin VoiceSessionLifecycleMixin<T extends StatefulWidget> on State<T> {
  AppLifecycleListener? _voiceLifecycleListener;

  /// Stop recognition / recording / TTS for this screen.
  Future<void> stopActiveVoiceSession();

  void startVoiceLifecycleWatch() {
    _voiceLifecycleListener?.dispose();
    _voiceLifecycleListener = AppLifecycleListener(
      onInactive: () {
        stopActiveVoiceSession();
      },
      onPause: () {
        stopActiveVoiceSession();
      },
      onDetach: () {
        stopActiveVoiceSession();
      },
      onHide: () {
        stopActiveVoiceSession();
      },
    );
  }

  void stopVoiceLifecycleWatch() {
    _voiceLifecycleListener?.dispose();
    _voiceLifecycleListener = null;
  }
}
