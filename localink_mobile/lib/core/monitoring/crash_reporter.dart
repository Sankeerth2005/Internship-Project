import 'package:flutter/foundation.dart';

/// Central crash / error reporting hook.
/// Wire Sentry or Firebase Crashlytics here when a DSN / project is configured.
class CrashReporter {
  CrashReporter._();

  static void recordFlutterError(FlutterErrorDetails details) {
    if (kDebugMode) {
      FlutterError.presentError(details);
      return;
    }
    FlutterError.presentError(details);
    debugPrint('CrashReporter FlutterError: ${details.exceptionAsString()}');
    // TODO: Sentry.captureException(details.exception, stackTrace: details.stack);
  }

  static void recordZoneError(Object error, StackTrace stack) {
    debugPrint('CrashReporter zone error: $error\n$stack');
    // TODO: Sentry.captureException(error, stackTrace: stack);
  }
}
