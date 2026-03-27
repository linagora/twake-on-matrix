import '../log_types.dart';
import '../logger.dart';
import 'mobile_log_console.dart'
    if (dart.library.html) 'web_log_console.dart'
    as console_log;

class ConsoleLogger implements Logger {
  @override
  void log(LogEntry entry) {
    // Determine color based on level
    // ANSI escape codes for colors (work in some terminals, debug consoles may strip them)
    // For Flutter debug console, it's often better to just print.
    // We can use debugPrint for better handling in Flutter.

    final timestamp = entry.timestamp.toIso8601String();
    final level = entry.level.toString().split('.').last.toUpperCase();
    String message = '$timestamp [$level] ${entry.message}';

    if (entry.error != null) {
      message += '\nError: ${entry.error}';
    }

    if (entry.stackTrace != null) {
      message += '\nStack: ${entry.stackTrace}';
    }

    if (entry.context != null && entry.context!.isNotEmpty) {
      message += '\nContext: ${entry.context}';
    }

    console_log.log(message);
  }
}
