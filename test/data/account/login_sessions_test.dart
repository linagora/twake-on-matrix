import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/presentation/model/client_login_state_event.dart';
import 'package:twake_chat/data/account/login_session.dart';
import 'package:twake_chat/data/account/login_sessions.dart';

import 'fakes.dart';
import 'fake_login_host.dart';

/// A host whose listeners fail when they are cancelled.
class _FailingCancelHost extends FakeLoginHost {
  @override
  StreamSubscription<LoginState> listenLoginState(
    Client client,
    void Function(LoginState state) onState,
  ) => _FailingCancel(super.listenLoginState(client, onState));
}

class _FailingCancel implements StreamSubscription<LoginState> {
  _FailingCancel(this._inner);

  final StreamSubscription<LoginState> _inner;

  @override
  Future<void> cancel() async {
    await _inner.cancel();
    throw StateError('cancel failed');
  }

  @override
  void onData(void Function(LoginState data)? handleData) =>
      _inner.onData(handleData);

  @override
  void onError(Function? handleError) => _inner.onError(handleError);

  @override
  void onDone(void Function()? handleDone) => _inner.onDone(handleDone);

  @override
  void pause([Future<void>? resumeSignal]) => _inner.pause(resumeSignal);

  @override
  void resume() => _inner.resume();

  @override
  bool get isPaused => _inner.isPaused;

  @override
  Future<E> asFuture<E>([E? futureValue]) => _inner.asFuture(futureValue);
}

void main() {
  late FakeLoginHost host;
  late LoginSessions sessions;

  setUp(() {
    host = FakeLoginHost();
    sessions = LoginSessions(host);
  });

  Iterable<MultipleAccountLoginType> events() =>
      host.events.map((e) => e.multipleAccountLoginType);

  /// The client [id] reports `loggedOut`, as the SDK does.
  Future<void> logOut(String id) async {
    host.loggedIn.remove(id);
    host.streams[id]!.add(LoginState.loggedOut);
    await pumpEventQueue();
  }

  group('loginClient', () {
    test('reuses the placeholder of a logged-out boot', () async {
      host.reusable = host.clientOf('boot');

      final client = await sessions.loginClient();

      expect(client, same(host.clientOf('boot')));
      expect(host.calls, isEmpty);
    });

    test('a failing retry is reported and the login goes on', () async {
      host.onRemovalRetry = () => throw StateError('retry failed');

      final client = await sessions.loginClient();

      expect(client, same(host.clientOf('c1')));
      expect(host.reports, ['retry of the failed cleanups']);
    });

    test('registers the candidate before a slow retry ends', () async {
      host.removalGate = Completer<void>();

      final login = sessions.loginClient();
      await pumpEventQueue();

      expect(sessions.sessionOf('c1'), isNotNull);

      host.removalGate!.complete();
      expect((await login).clientName, 'c1');
    });

    test('makes one candidate for calls made at the same time', () async {
      host.gates['createCandidate:c1'] = Completer<void>();

      final first = sessions.loginClient();
      final second = sessions.loginClient();
      await pumpEventQueue();
      host.gates['createCandidate:c1']!.complete();

      expect(await first, same(await second));
      expect(host.calls.where((c) => c.startsWith('createCandidate')), [
        'createCandidate:c1',
      ]);
    });

    test('hands out the pending candidate again while it can log in', () async {
      final first = await sessions.loginClient();

      final second = await sessions.loginClient();

      expect(second, same(first));
      expect(host.calls, ['createCandidate:c1']);
    });

    test('makes a new candidate once the pending one is gone', () async {
      await sessions.loginClient();
      await sessions.discardPending();

      final next = await sessions.loginClient();

      expect(next.clientName, 'c2');
    });

    test('a creation that fails reaches the caller and is not kept', () async {
      host.failing.add('createCandidate:c1');
      await expectLater(sessions.loginClient(), throwsStateError);
      host.failing.clear();

      final client = await sessions.loginClient();

      expect(client.clientName, 'c2');
    });

    test('retries a cleanup that failed before handing out a client', () async {
      final client = await sessions.loginClient();
      host.failing.addAll(['switchTo:c1', 'removeAccount:c1']);
      host.logIn(client.clientName);
      await pumpEventQueue();
      expect(sessions.sessionOf('c1')!.state, LoginSessionState.cleanupFailed);
      host.failing.remove('removeAccount:c1');
      host.calls.clear();

      await sessions.loginClient();

      expect(host.calls, contains('removeAccount:c1'));
      expect(sessions.sessionOf('c1')!.state, LoginSessionState.disposed);
    });
  });

  group('a pending candidate whose cleanup failed', () {
    test('is not handed out again as the reusable client', () async {
      final client = await sessions.loginClient();
      host.failing.addAll(['switchTo:c1', 'removeAccount:c1']);
      host.logIn(client.clientName);
      await pumpEventQueue();
      expect(sessions.sessionOf('c1')!.state, LoginSessionState.cleanupFailed);
      host.reusable = client;

      final next = await sessions.loginClient();

      expect(next.clientName, 'c2');
    });
  });

  group('a placeholder that cannot take a login', () {
    test('is not handed out: the screen gets a new candidate it can log in '
        'with', () async {
      final boot = host.clientOf('boot');
      host.activeName = 'boot';
      host.reusable = boot;
      // The rollback fails, and so does its retry.
      host.failing.addAll(['activateCurrent', 'logoutLast']);
      await sessions.onLoggedIn(boot, LoginState.loggedIn);
      expect(
        sessions.sessionOf('boot')!.state,
        LoginSessionState.cleanupFailed,
      );

      final next = await sessions.loginClient();

      expect(next.clientName, 'c1');
      await expectLater(
        sessions.trackLogin(next, () async => 'logged in'),
        completion('logged in'),
      );
      expect(
        sessions.sessionOf('boot')!.state,
        LoginSessionState.cleanupFailed,
      );
    });

    test('is not handed out while its rollback is still running', () async {
      final boot = host.clientOf('boot');
      host.reusable = boot;
      host.failing.add('activateCurrent');
      host.gates['apply:a'] = Completer<void>();
      final logging = sessions.onLoggedIn(boot, LoginState.loggedIn);
      await pumpEventQueue();
      expect(sessions.sessionOf('boot')!.state, LoginSessionState.rollingBack);

      final next = sessions.loginClient();
      await pumpEventQueue();
      host.gates['apply:a']!.complete();

      expect((await next).clientName, 'c1');
      await logging;
      await expectLater(
        sessions.trackLogin(host.clientOf('c1'), () async => 'ok'),
        completion('ok'),
      );
      expect(
        sessions.sessionOf('boot')!.state,
        isNot(LoginSessionState.rollingBack),
      );
    });
  });

  group('a retry that ends the client waited for', () {
    test('the placeholder it ended is not handed out', () async {
      host.reusable = host.clientOf('boot');
      host.onRemovalRetry = () => host.reusable = null;

      final client = await sessions.loginClient();

      expect(client.clientName, 'c1');
      expect(client, isNot(same(host.clientOf('boot'))));
    });
  });

  group('failed removals of logged-out accounts', () {
    test('are retried before a client is handed out', () async {
      await sessions.loginClient();

      expect(host.removalRetries, 1);

      await sessions.loginClient();

      expect(host.removalRetries, 2);
    });
  });

  group('discardPending', () {
    test('does nothing without a candidate', () async {
      await sessions.discardPending();

      expect(host.calls, isEmpty);
    });

    test('waits for the creation, then discards: nothing leaks', () async {
      host.gates['createCandidate:c1'] = Completer<void>();
      final client = sessions.loginClient();
      final discarded = sessions.discardPending();
      await pumpEventQueue();

      host.gates['createCandidate:c1']!.complete();
      await client;
      await discarded;

      expect(host.calls, contains('discardCandidate:c1'));
      expect(host.pending, isNull);
    });

    test('is idempotent, also when asked twice at once', () async {
      await sessions.loginClient();

      await Future.wait([sessions.discardPending(), sessions.discardPending()]);
      await sessions.discardPending();

      expect(host.calls.where((c) => c == 'discardCandidate:c1'), hasLength(1));
    });

    test('waits for a login that is going on', () async {
      final client = await sessions.loginClient();
      final login = Completer<void>();
      unawaited(
        sessions.trackLogin(client, () => login.future).catchError((_) {}),
      );

      final discarded = sessions.discardPending();
      await pumpEventQueue();
      expect(host.calls, isNot(contains('discardCandidate:c1')));

      login.completeError(StateError('wrong password'));
      await discarded;

      expect(host.calls, contains('discardCandidate:c1'));
    });

    test('keeps a candidate that became an account', () async {
      final client = await sessions.loginClient();
      host.logIn(client.clientName);
      await pumpEventQueue();
      host.calls.clear();

      await sessions.discardPending();

      expect(host.calls, isEmpty);
    });
  });

  group('onLoggedIn', () {
    Future<LoginSession> activeWithFailedTom() async {
      host.failing.add('tom:a');
      await sessions.onLoggedIn(host.clientOf('a'), LoginState.loggedIn);
      final session = sessions.sessionOf('a')!;
      expect(session.needsRetry, isTrue);
      return session;
    }

    test('starts a session for the placeholder and registers it', () async {
      await sessions.onLoggedIn(host.clientOf('a'), LoginState.loggedIn);

      expect(sessions.sessionOf('a')!.state, LoginSessionState.active);
      expect(events(), [MultipleAccountLoginType.firstLoggedIn]);
    });

    test(
      'a client that logs in again after a logout gets a fresh run',
      () async {
        await sessions.onLoggedIn(host.clientOf('a'), LoginState.loggedIn);
        await logOut('a');
        host.loggedIn.add('a');
        host.calls.clear();

        await sessions.onLoggedIn(host.clientOf('a'), LoginState.loggedIn);

        expect(host.calls, contains('activateCurrent'));
      },
    );

    test(
      'a repeated loggedIn of an active candidate keeps its session: no placeholder, no firstLoggedIn',
      () async {
        final client = await sessions.loginClient();
        host.logIn(client.clientName);
        await pumpEventQueue();
        final session = sessions.sessionOf('c1');
        host.calls.clear();
        host.events.clear();

        await sessions.onLoggedIn(client, LoginState.loggedIn);

        expect(sessions.sessionOf('c1'), same(session));
        expect(session!.keepsClient, isFalse);
        expect(session.state, LoginSessionState.active);
        expect(host.calls, isEmpty);
        expect(host.events, isEmpty);
      },
    );

    test('replacing an active session cancels its listener and retries the '
        'set-ups that failed', () async {
      final first = await activeWithFailedTom();
      expect(host.openListeners('a'), 1);

      host.calls.clear();
      await sessions.trackLogin(host.clientOf('a'), () async {});

      expect(host.calls, contains('tom:a'));
      expect(host.openListeners('a'), 1);
      expect(first.needsRetry, isTrue);
      expect(sessions.sessionOf('a'), isNot(same(first)));

      host.failing.remove('tom:a');
      host.calls.clear();
      await sessions.retryFailedCleanups();

      expect(host.calls, contains('tom:a'));
      expect(first.needsRetry, isFalse);
      expect(host.openListeners('a'), 1);
    });

    test('a login try on an active placeholder starts a new session that sets '
        'the account up again', () async {
      final first = await activeWithFailedTom();
      await logOut('a');
      host.failing.clear();
      host.calls.clear();

      await sessions.trackLogin(host.clientOf('a'), () async {});
      host.logIn('a');
      await sessions.onLoggedIn(host.clientOf('a'), LoginState.loggedIn);

      final second = sessions.sessionOf('a')!;
      expect(second, isNot(same(first)));
      expect(second.state, LoginSessionState.active);
      expect(second.needsRetry, isFalse);
      expect(host.calls, contains('tom:a'));
    });

    test('a client the app no longer knows gets no session', () async {
      await sessions.onLoggedIn(
        FakeAccountClient('gone', userID: '@gone:s'),
        LoginState.loggedIn,
      );

      expect(sessions.sessionOf('gone'), isNull);
      expect(host.calls, isEmpty);
    });
  });

  group('disposed sessions', () {
    test('are dropped when the next attempt starts', () async {
      await sessions.loginClient();
      await sessions.discardPending();
      expect(sessions.sessionOf('c1')!.state, LoginSessionState.disposed);

      await sessions.loginClient();

      expect(sessions.sessionOf('c1'), isNull);
      expect(sessions.sessionOf('c2'), isNotNull);
    });
  });

  group('the host goes away', () {
    /// A candidate that listens for its login, and the watch of a placeholder.
    Future<void> openSessions() async {
      await sessions.loginClient();
      await sessions.trackLogin(host.clientOf('boot'), () async {});
      expect(host.openListeners('c1'), 1);
      expect(host.openListeners('boot'), 1);
    }

    test('release cancels the listeners of the sessions it drops', () async {
      await openSessions();

      sessions.release(host);
      await pumpEventQueue();

      expect(host.openListeners('c1'), 0);
      expect(host.openListeners('boot'), 0);
      expect(sessions.sessionOf('c1'), isNull);
    });

    test(
      'attach cancels the listeners of the previous host sessions',
      () async {
        await openSessions();

        sessions.attach(FakeLoginHost());
        await pumpEventQueue();

        expect(host.openListeners('c1'), 0);
        expect(host.openListeners('boot'), 0);
      },
    );

    test('release by a host that is not attached drops nothing', () async {
      await openSessions();

      sessions.release(FakeLoginHost());
      await pumpEventQueue();

      expect(host.openListeners('c1'), 1);
      expect(sessions.sessionOf('c1'), isNotNull);
    });

    test('a cancel that fails is reported and is not left uncaught', () async {
      final failingHost = _FailingCancelHost();
      sessions = LoginSessions(failingHost);
      await sessions.loginClient();
      await sessions.trackLogin(failingHost.clientOf('boot'), () async {});
      final uncaught = <Object>[];

      await runZonedGuarded(() async {
        sessions.release(failingHost);
        await pumpEventQueue();
      }, (error, _) => uncaught.add(error));

      expect(uncaught, isEmpty);
      expect(failingHost.reports, [
        'login listener cancel of c1 failed',
        'logged-out listener cancel of boot failed',
      ]);
    });
  });

  group('trackLogin', () {
    test('returns what the login returns and passes its error on', () async {
      final client = await sessions.loginClient();

      expect(await sessions.trackLogin(client, () async => 7), 7);
      await expectLater(
        sessions.trackLogin(client, () async => throw StateError('x')),
        throwsStateError,
      );
    });
  });
}
