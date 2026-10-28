import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/providers/report_failure_provider.dart';

void main() {
  test('a failure is logged as wtf with its error and stack', () {
    final events = <LogEvent>[];
    final previous = Logs().onLog;
    Logs().onLog = events.add;
    addTearDown(() => Logs().onLog = previous);
    final container = ProviderContainer.test();
    final error = Exception('/logout failed');
    final stackTrace = StackTrace.current;

    container.read(reportFailureProvider)(error, stackTrace, 'where');

    expect(events, hasLength(1));
    // `Level.wtf` is what the Sentry logger forwards unconditionally.
    expect(events.single.level, Level.wtf);
    expect(events.single.title, 'where');
    expect(events.single.exception, same(error));
    expect(events.single.stackTrace, same(stackTrace));
  });
}
