import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/account/login_state_watcher.dart';

void main() {
  late StreamController<LoginState> source;
  late List<LoginState> seen;
  late List<Object> uncaught;

  setUp(() {
    source = StreamController<LoginState>.broadcast();
    seen = [];
    uncaught = [];
  });

  tearDown(() => source.close());

  bool loggedError(String part) => Logs().outputEvents.any(
    (event) => event.level == Level.error && event.title.contains(part),
  );

  Future<void> run(Future<void> Function() body) async {
    Logs().outputEvents.clear();
    await runZonedGuarded(body, (error, _) => uncaught.add(error));
    await pumpEventQueue();
  }

  test('hands the login states to the handler', () async {
    await run(() async {
      const LoginStateWatcher().watch(source.stream, seen.add);
      source.add(LoginState.loggedIn);
      source.add(LoginState.loggedOut);
    });

    expect(seen, [LoginState.loggedIn, LoginState.loggedOut]);
  });

  test('an error on the stream is handled, not thrown to the zone', () async {
    await run(() async {
      const LoginStateWatcher().watch(source.stream, seen.add);
      source.addError(StateError('presence failed'));
    });

    expect(uncaught, isEmpty);
    expect(loggedError('error on the login state'), isTrue);
  });

  test('states after an error still reach the handler', () async {
    await run(() async {
      const LoginStateWatcher().watch(source.stream, seen.add);
      source.addError(StateError('presence failed'));
      source.add(LoginState.loggedOut);
    });

    expect(seen, [LoginState.loggedOut]);
  });

  group('track', () {
    test('cancel waits for a handler that is still running', () async {
      final release = Completer<void>();
      final tracked = const LoginStateWatcher().track(source.stream, (_) async {
        await release.future;
        seen.add(LoginState.loggedOut);
      });
      source.add(LoginState.loggedOut);
      await pumpEventQueue();

      var cancelled = false;
      final done = tracked.cancel().then((_) => cancelled = true);
      await pumpEventQueue();
      expect(cancelled, isFalse);

      release.complete();
      await done;

      expect(seen, [LoginState.loggedOut]);
    });

    test('a handler that fails is logged, not thrown to the zone', () async {
      await run(() async {
        const LoginStateWatcher().track(
          source.stream,
          (_) async => throw StateError('handler'),
        );
        source.add(LoginState.loggedOut);
      });

      expect(uncaught, isEmpty);
      expect(loggedError('a handler failed'), isTrue);
    });

    test(
      'a handler that cancels its own listener does not wait for itself',
      () async {
        late TrackedLoginStates tracked;
        final finished = Completer<void>();
        tracked = const LoginStateWatcher().track(source.stream, (_) async {
          await Future<void>.delayed(Duration.zero);
          await tracked.cancel();
          finished.complete();
        });

        source.add(LoginState.loggedOut);

        await finished.future.timeout(const Duration(seconds: 2));
      },
    );

    test('cancel with nothing running returns at once', () async {
      final tracked = const LoginStateWatcher().track(
        source.stream,
        (_) async {},
      );

      await tracked.cancel().timeout(const Duration(seconds: 2));
    });
  });
}
