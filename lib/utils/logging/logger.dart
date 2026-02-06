import 'log_types.dart';

abstract class Logger {
  /// Handles the log entry.
  void log(LogEntry entry);
}
