import 'package:fluffychat/utils/logging/log_orchestrator.dart';
import 'package:fluffychat/utils/logging/log_types.dart';
import 'package:matrix/matrix_api_lite/utils/logs.dart';

void initMatrixLogger() {
  Logs().onLog = (LogEvent event) {
    final logLevel = switch (event.level) {
      Level.info => LogLevel.info,
      Level.warning => LogLevel.warn,
      Level.error => LogLevel.error,
      Level.wtf => LogLevel.wtf,
      _ => LogLevel.debug,
    };

    LogOrchestrator().log(
      LogEntry(
        message: event.title,
        level: logLevel,
        error: event.exception,
        stackTrace: event.stackTrace,
      ),
    );
  };
}
