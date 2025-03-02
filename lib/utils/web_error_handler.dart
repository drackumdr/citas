import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class WebErrorHandler {
  static void initialize() {
    // Set up error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        // In development mode, print errors to console
        FlutterError.dumpErrorToConsole(details);
      } else {
        // In production, report to Crashlytics if not on web
        if (!kIsWeb) {
          FirebaseCrashlytics.instance.recordFlutterError(details);
        } else {
          // For web, we could implement custom error logging
          print('Web Error: ${details.exception}');
        }
      }
    };
  }
}
