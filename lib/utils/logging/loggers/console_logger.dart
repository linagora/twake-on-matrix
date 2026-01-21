import 'package:flutter/foundation.dart';
import '../log_types.dart';
import '../logger.dart';

class ConsoleLogger implements Logger {
  @override
  void log(LogEntry entry) {
    // Determine color based on level
    // ANSI escape codes for colors (work in some terminals, debug consoles may strip them)
    // For Flutter debug console, it's often better to just print.
    // We can use debugPrint for better handling in Flutter.

    final timestamp = entry.timestamp.toIso8601String();
    final level = entry.level.toString().split('.').last.toUpperCase();
    final message = '$timestamp [$level] ${entry.message}';

    if (entry.error != null) {
      debugPrint('$message\nError: ${entry.error}\nStack: ${entry.stackTrace}');
    } else {
      debugPrint(message);
    }

    if (entry.context != null && entry.context!.isNotEmpty) {
      debugPrint('Context: ${entry.context}');
    }
  }
}
