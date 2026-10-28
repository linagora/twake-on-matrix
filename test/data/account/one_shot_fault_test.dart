import 'package:flutter_test/flutter_test.dart';

import 'one_shot_fault.dart';

void main() {
  test('is disarmed by default', () {
    final fault = OneShotFault();

    fault.maybeThrow('a');
    fault.maybeThrow('b');
  });

  test('fails once when armed, then lets the calls through', () {
    final fault = OneShotFault(armed: true);

    expect(
      () => fault.maybeThrow('a'),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          'Injected fault: a',
        ),
      ),
    );
    fault.maybeThrow('a');
  });

  test('lets the first calls through when asked to', () {
    final fault = OneShotFault(armed: true, succeedFirst: 2);

    fault.maybeThrow('a');
    fault.maybeThrow('b');
    expect(() => fault.maybeThrow('c'), throwsStateError);
    fault.maybeThrow('d');
  });

  test('does not count the calls down while disarmed', () {
    final fault = OneShotFault(succeedFirst: 1);

    fault.maybeThrow('a');
    fault.maybeThrow('b');
  });
}
