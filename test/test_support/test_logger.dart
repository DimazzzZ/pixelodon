import 'package:logger/logger.dart';
import 'package:pixelodon/utils/logger.dart' as app_logger;

/// Suppresses all logger output during tests.
/// Call this in setUp() to prevent logger messages from cluttering test output.
void suppressLoggerOutput() {
  Logger.level = Level.off;
}

/// Restores logger output after tests.
/// Call this in tearDown() if you want to restore logging.
void restoreLoggerOutput() {
  Logger.level = Level.debug;
}
