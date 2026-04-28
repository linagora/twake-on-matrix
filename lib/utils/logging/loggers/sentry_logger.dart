import 'package:fluffychat/utils/logging/log_types.dart';
import 'package:fluffychat/utils/logging/logger.dart';
import 'package:fluffychat/utils/logging/sentry_tracked_events.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class SentryLogger implements Logger {
  @override
  Future<void> log(LogEntry entry) async {
    final isWtf = entry.level == LogLevel.wtf;
    final isTracked = SentryTrackedEvents.active.any(
      (e) => entry.message.contains(e.message),
    );

    if (!isWtf && !isTracked) return;

    if (entry.error != null) {
      await Sentry.captureException(
        entry.error,
        stackTrace: entry.stackTrace,
        message: SentryMessage(entry.message),
      );
    } else {
      await Sentry.captureMessage(
        entry.message,
        level: isWtf ? SentryLevel.fatal : SentryLevel.warning,
      );
    }
  }
}
