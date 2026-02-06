import 'package:pixelodon/utils/logger.dart';

/// Centralized error reporting and handling utility
class ErrorReporter {
  /// Report an error to the log and potentially to a remote service
  static void report(
    dynamic error, {
    StackTrace? stackTrace,
    String? message,
    Map<String, dynamic>? extra,
  }) {
    final errorMessage = message ?? error.toString();
    logger.e(
      errorMessage,
      error: error,
      stackTrace: stackTrace,
    );
    
    if (extra != null && extra.isNotEmpty) {
      logger.d('Error extra info: $extra');
    }
    
    // TODO: Integrate with remote reporting service (e.g., Sentry, Crashlytics)
  }

  /// Log a warning that doesn't necessarily mean a crash or failure
  static void warn(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    logger.w(message, error: error, stackTrace: stackTrace);
  }
}
