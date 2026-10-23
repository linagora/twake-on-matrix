import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/providers/login_faults.dart';

void main() {
  test('fails the set-up once when armed, then lets it through', () {
    final faults = LoginFaults(failSetUpOnce: true, succeedFirst: 0);

    expect(() => faults.maybeFailSetUp('a'), throwsStateError);
    faults.maybeFailSetUp('a');
  });

  test('lets the first set-ups through when asked to', () {
    final faults = LoginFaults(failSetUpOnce: true, succeedFirst: 1);

    faults.maybeFailSetUp('a');
    expect(() => faults.maybeFailSetUp('b'), throwsStateError);
    faults.maybeFailSetUp('b');
  });

  test('does nothing when not armed', () {
    final faults = LoginFaults(failSetUpOnce: false);

    faults.maybeFailSetUp('a');
    faults.maybeFailSetUp('b');
  });
}
