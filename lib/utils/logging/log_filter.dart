import 'log_types.dart';

abstract class LogFilter {
  /// Filters the log entry.
  ///
  /// Returns `null` if the log should be dropped.
  /// Returns a [LogEntry] (possibly modified) if it should be processed.
  LogEntry? filter(LogEntry entry);
}
