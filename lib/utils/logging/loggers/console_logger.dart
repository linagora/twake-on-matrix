import 'dart:developer' as developer;
import 'dart:js_interop';

import 'package:fluffychat/utils/platform_infos.dart';
import 'package:web/web.dart' show console;
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

    if (PlatformInfos.isWeb) {
      console.log(message.toJS);
    } else {
      developer.log(message);
    }
  }
}
