import 'package:matrix/matrix_api_lite/utils/logs.dart';

/// Makes a failed logout step visible while the local cleanup goes on
/// (local-first logout): logged with its stack trace at the level the error
/// reporting picks up, so it reaches Sentry.
class LogoutFailureReporter {
  const LogoutFailureReporter();

  void report(String where, Object error, StackTrace stackTrace) {
    Logs().wtf(
      '$where - logout step failed, local cleanup continues',
      error,
      stackTrace,
    );
  }
}
