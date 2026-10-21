import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/presentation/model/client_login_state_event.dart';
import 'package:twake_chat/providers/login_session.dart';
import 'package:twake_chat/providers/login_sessions.dart';

import '../data/account/fakes.dart';
import 'fake_login_host.dart';

void main() {
  late FakeLoginHost host;
  late LoginSessions sessions;

  setUp(() {
    host = FakeLoginHost();
    sessions = LoginSessions(host);
  });

  Iterable<MultipleAccountLoginType> events() =>
      host.events.map((e) => e.multipleAccountLoginType);

  group('loginClient', () {
    test('reuses the placeholder of a logged-out boot', () async {
      host.reusable = host.clientOf('boot');

      final client = await sessions.loginClient();

      expect(client, same(host.clientOf('boot')));
      expect(host.calls, isEmpty);
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

  group('firstLoggedIn', () {
    test('starts a session for the placeholder and registers it', () async {
      await sessions.firstLoggedIn(host.clientOf('a'), LoginState.loggedIn);

      expect(sessions.sessionOf('a')!.state, LoginSessionState.active);
      expect(events(), [MultipleAccountLoginType.firstLoggedIn]);
    });

    test('a client that logs in again gets a fresh run', () async {
      await sessions.firstLoggedIn(host.clientOf('a'), LoginState.loggedIn);
      host.calls.clear();

      await sessions.firstLoggedIn(host.clientOf('a'), LoginState.loggedIn);

      expect(host.calls, contains('activateCurrent'));
    });

    test(
      'a repeated loggedIn of an active candidate keeps its session: no placeholder, no firstLoggedIn',
      () async {
        final client = await sessions.loginClient();
        host.logIn(client.clientName);
        await pumpEventQueue();
        final session = sessions.sessionOf('c1');
        host.calls.clear();
        host.events.clear();

        await sessions.firstLoggedIn(client, LoginState.loggedIn);

        expect(sessions.sessionOf('c1'), same(session));
        expect(session!.keepsClient, isFalse);
        expect(session.state, LoginSessionState.active);
        expect(host.calls, isEmpty);
        expect(host.events, isEmpty);
      },
    );

    test('a client the app no longer knows gets no session', () async {
      await sessions.firstLoggedIn(
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
