enum LogLevel { debug, info, warn, error, wtf }

class LogEntry {
  final String message;
  final LogLevel level;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? context;
  final DateTime timestamp;

  LogEntry({
    required this.message,
    required this.level,
    this.error,
    this.stackTrace,
    this.context,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  LogEntry copyWith({
    String? message,
    LogLevel? level,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    DateTime? timestamp,
  }) {
    return LogEntry(
      message: message ?? this.message,
      level: level ?? this.level,
      error: error ?? this.error,
      stackTrace: stackTrace ?? this.stackTrace,
      context: context ?? this.context,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'LogEntry(level: $level, message: $message, timestamp: $timestamp, error: $error)';
  }
}
