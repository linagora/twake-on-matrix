import 'package:fluffychat/utils/logging/log_types.dart';
import 'package:fluffychat/utils/logging/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class SentryLogger implements Logger {
  @override
  Future<void> log(LogEntry entry) async {
    if (entry.level == LogLevel.wtf) {
      await Sentry.captureException(
        entry.error,
        stackTrace: entry.stackTrace,
        message: SentryMessage(entry.message),
      );
    }
  }
}
