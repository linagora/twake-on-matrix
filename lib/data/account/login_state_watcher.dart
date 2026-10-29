import 'dart:async';

import 'package:matrix/matrix.dart';

/// Listens to the login state of a client. An error put on that stream (for
/// example by the start-up code) is logged here, so it is never an uncaught
/// async error.
class LoginStateWatcher {
  const LoginStateWatcher();

  StreamSubscription<LoginState> watch(
    Stream<LoginState> states,
    void Function(LoginState state) onState,
  ) => states.listen(
    onState,
    onError: (Object error, StackTrace stackTrace) => Logs().e(
      'LoginStateWatcher: error on the login state',
      error,
      stackTrace,
    ),
  );

  /// Like [watch], for a handler that takes time. The handler's future is
  /// kept, its failure is logged, and [TrackedLoginStates.cancel] waits for it.
  TrackedLoginStates track(
    Stream<LoginState> states,
    Future<void> Function(LoginState state) handler,
  ) => TrackedLoginStates._(states, handler);
}

/// A listener of login states whose handlers are awaited when it is cancelled.
class TrackedLoginStates {
  TrackedLoginStates._(
    Stream<LoginState> states,
    Future<void> Function(LoginState state) handler,
  ) {
    _subscription = const LoginStateWatcher().watch(states, (state) {
      late final Future<void> run;
      run = _run(handler, state).whenComplete(() => _handlers.remove(run));
      _handlers.add(run);
    });
  }

  late final StreamSubscription<LoginState> _subscription;
  final Set<Future<void>> _handlers = {};

  Future<void> _run(
    Future<void> Function(LoginState state) handler,
    LoginState state,
  ) async {
    try {
      // Marked, so a handler that cancels its own listener does not wait for
      // itself.
      await runZoned(() => handler(state), zoneValues: {this: true});
    } catch (error, stackTrace) {
      Logs().e('LoginStateWatcher: a handler failed', error, stackTrace);
    }
  }

  /// Stops listening and waits for the handlers that are running, unless this
  /// is called from one of them.
  Future<void> cancel() async {
    await _subscription.cancel();
    if (Zone.current[this] == true) return;
    await Future.wait(_handlers.toList());
  }
}
