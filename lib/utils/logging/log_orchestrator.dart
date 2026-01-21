import 'package:flutter/foundation.dart' show debugPrint;

import 'log_filter.dart';
import 'log_types.dart';
import 'logger.dart';

class LogOrchestrator {
  final List<Logger> _loggers = [];
  final List<LogFilter> _filters = [];

  // Singleton instance
  static final LogOrchestrator _instance = LogOrchestrator._internal();

  factory LogOrchestrator() {
    return _instance;
  }

  LogOrchestrator._internal();

  void addLogger(Logger logger) {
    if (!_loggers.contains(logger)) {
      _loggers.add(logger);
    }
  }

  void removeLogger(Logger logger) {
    _loggers.remove(logger);
  }

  void addFilter(LogFilter filter) {
    if (!_filters.contains(filter)) {
      _filters.add(filter);
    }
  }

  void removeFilter(LogFilter filter) {
    _filters.remove(filter);
  }

  void log(LogEntry entry) {
    LogEntry? currentEntry = entry;

    for (final filter in _filters) {
      currentEntry = filter.filter(currentEntry!);
      if (currentEntry == null) {
        // Log dropped by filter
        return;
      }
    }

    for (final logger in _loggers) {
      try {
        logger.log(currentEntry!);
      } catch (e, stackTrace) {
        // Prevent logger errors from crashing the app
        // Fallback to simple print if possible, or just ignore to avoid infinite loops if it's the console logger failing
        debugPrint('Error in logger: $e\n$stackTrace');
      }
    }
  }

  // Convenience methods
  void debug(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    log(
      LogEntry(
        message: message,
        level: LogLevel.debug,
        error: error,
        stackTrace: stackTrace,
        context: context,
      ),
    );
  }

  void info(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    log(
      LogEntry(
        message: message,
        level: LogLevel.info,
        error: error,
        stackTrace: stackTrace,
        context: context,
      ),
    );
  }

  void warn(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    log(
      LogEntry(
        message: message,
        level: LogLevel.warn,
        error: error,
        stackTrace: stackTrace,
        context: context,
      ),
    );
  }

  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    log(
      LogEntry(
        message: message,
        level: LogLevel.error,
        error: error,
        stackTrace: stackTrace,
        context: context,
      ),
    );
  }
}
