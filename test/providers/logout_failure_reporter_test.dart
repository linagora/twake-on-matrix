import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/providers/logout_failure_reporter.dart';

void main() {
  test('a failed logout step is logged as wtf with its error and stack', () {
    final events = <LogEvent>[];
    final previous = Logs().onLog;
    Logs().onLog = events.add;
    addTearDown(() => Logs().onLog = previous);
    final error = Exception('/logout failed');
    final stackTrace = StackTrace.current;

    const LogoutFailureReporter().report('where', error, stackTrace);

    expect(events, hasLength(1));
    // `Level.wtf` is what the Sentry logger forwards unconditionally.
    expect(events.single.level, Level.wtf);
    expect(events.single.exception, same(error));
    expect(events.single.stackTrace, same(stackTrace));
  });
}
