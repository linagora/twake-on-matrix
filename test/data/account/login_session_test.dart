import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/presentation/model/client_login_state_event.dart';
import 'package:twake_chat/data/account/login_session.dart';

import 'fake_login_host.dart';

void main() {
  late FakeLoginHost host;

  setUp(() => host = FakeLoginHost());

  Future<LoginSession> candidate() async {
    final session = LoginSession.candidate(host);
    await session.ready;
    return session;
  }

  Future<void> logIn(LoginSession session) async {
    host.logIn(session.id);
    await pumpEventQueue();
  }

  Iterable<MultipleAccountLoginType> events() =>
      host.events.map((e) => e.multipleAccountLoginType);

  group('the states', () {
    test('say which ones are live and which a screen can use', () {
      final flags = {
        for (final state in LoginSessionState.values)
          state: (state.isLive, state.isUsable),
      };

      expect(flags, {
        LoginSessionState.creating: (true, true),
        LoginSessionState.created: (true, true),
        LoginSessionState.loggingIn: (true, true),
        LoginSessionState.registering: (true, false),
        LoginSessionState.active: (false, false),
        LoginSessionState.rollingBack: (true, false),
        LoginSessionState.disposed: (false, false),
        LoginSessionState.cleanupFailed: (true, false),
      });
    });
  });

  group('creating', () {
    test(
      'creating -> created: the client exists and is the pending one',
      () async {
        host.gates['createCandidate:c1'] = Completer<void>();
        final session = LoginSession.candidate(host);
        await pumpEventQueue();
        expect(session.state, LoginSessionState.creating);
        expect(host.pending, isNull);

        host.gates['createCandidate:c1']!.complete();
        final client = await session.ready;

        expect(session.state, LoginSessionState.created);
        expect(client.clientName, 'c1');
        expect(host.pending, 'c1');
      },
    );

    test(
      'a creation that fails ends disposed and the error reaches the caller',
      () async {
        host.failing.add('createCandidate:c1');
        final session = LoginSession.candidate(host);

        await expectLater(session.ready, throwsStateError);

        expect(session.state, LoginSessionState.disposed);
        expect(host.pending, isNull);
      },
    );
  });

  group('logging in', () {
    test(
      'created -> loggingIn, and a failed login goes back to created',
      () async {
        final session = await candidate();

        final login = session.trackLogin<void>(() async {
          throw StateError('wrong password');
        });
        expect(session.state, LoginSessionState.loggingIn);
        await expectLater(login, throwsStateError);
        await pumpEventQueue();

        expect(session.state, LoginSessionState.created);
      },
    );

    test('a login cannot start once the session is disposed', () async {
      final session = await candidate();
      await session.dispose();

      expect(() => session.trackLogin<void>(() async {}), throwsStateError);
    });
  });

  group('registering a candidate', () {
    test(
      'loggingIn -> registering -> active, in order, then reports',
      () async {
        final session = await candidate();
        unawaited(session.trackLogin<void>(() async => host.logIn('c1')));
        await pumpEventQueue();

        expect(session.state, LoginSessionState.active);
        expect(host.calls, [
          'createCandidate:c1',
          'addAccount:c1',
          'registerSubs:c1',
          'firstSyncDone',
          'tom:c1',
          'federation:c1',
          'recoveryKey:c1',
          'switchTo:c1',
          'push:c1',
          'cancelContactSync',
          'reSyncContacts',
          'emit:otherAccountLoggedIn',
        ]);
        expect(host.pending, isNull);
      },
    );

    test('a repeated loggedIn event is ignored', () async {
      final session = await candidate();
      await logIn(session);
      final count = host.calls.length;

      host.streams['c1']!.add(LoginState.loggedIn);
      await pumpEventQueue();

      expect(host.calls.length, count);
    });

    test(
      'registering is serialised: a second event waits for the first',
      () async {
        host.gates['addAccount:c1'] = Completer<void>();
        final session = await candidate();
        host.logIn('c1');
        await pumpEventQueue();
        expect(session.state, LoginSessionState.registering);

        host.streams['c1']!.add(LoginState.loggedIn);
        host.gates['addAccount:c1']!.complete();
        await pumpEventQueue();

        expect(host.calls.where((c) => c == 'addAccount:c1'), hasLength(1));
        expect(session.state, LoginSessionState.active);
      },
    );
  });

  group('rolling a candidate back', () {
    Future<LoginSession> failingAt(String step) async {
      final session = await candidate();
      host.failing.add(step);
      await logIn(session);
      return session;
    }

    for (final step in ['addAccount:c1', 'registerSubs:c1', 'switchTo:c1']) {
      test(
        'a fatal failure of $step ends disposed, with one loginFailed',
        () async {
          final session = await failingAt(step);

          expect(session.state, LoginSessionState.disposed);
          expect(events(), [MultipleAccountLoginType.loginFailed]);
          expect(host.stored, isEmpty);
          expect(host.pending, isNull);
          expect(host.calls, contains('forgetQuiet:c1'));
          expect(host.reports.first, 'login of c1 failed');
        },
      );
    }

    for (final step in [
      'tom:c1',
      'federation:c1',
      'recoveryKey:c1',
      'push:c1',
      'cancelContactSync',
    ]) {
      test('a failure of $step keeps the account and is reported', () async {
        final session = await failingAt(step);

        expect(session.state, LoginSessionState.active);
        expect(events(), [MultipleAccountLoginType.otherAccountLoggedIn]);
        expect(host.stored, {'c1'});
        expect(host.calls, isNot(contains('removeAccount:c1')));
        expect(host.reports, hasLength(1));
      });
    }

    test('a set-up that failed is run again by the retry', () async {
      final session = await failingAt('recoveryKey:c1');
      expect(session.needsRetry, isTrue);
      host.failing.clear();
      host.calls.clear();

      await session.retryCleanup();

      expect(host.calls, ['recoveryKey:c1']);
      expect(session.needsRetry, isFalse);
    });

    test('a switch that does not succeed is a failed login', () async {
      final session = await candidate();
      host.switchSucceeds = false;
      await logIn(session);

      expect(session.state, LoginSessionState.disposed);
      expect(events(), [MultipleAccountLoginType.loginFailed]);
      expect(host.calls, isNot(contains('push:c1')));
    });

    test(
      'a candidate that was not stored is discarded, a stored one removed',
      () async {
        final notStored = await failingAt('addAccount:c1');
        expect(host.calls, contains('discardCandidate:c1'));
        expect(host.calls, isNot(contains('removeAccount:c1')));
        expect(notStored.state, LoginSessionState.disposed);

        host.calls.clear();
        host.failing.clear();
        final stored = await candidate();
        host.failing.add('switchTo:c2');
        await logIn(stored);

        expect(host.calls, contains('removeAccount:c2'));
        expect(host.calls, isNot(contains('discardCandidate:c2')));
      },
    );

    test(
      'subscriptions are cancelled only after they were registered, then the sign-out, then the removal',
      () async {
        await failingAt('switchTo:c1');

        expect(
          host.calls,
          containsAllInOrder([
            'registerSubs:c1',
            'switchTo:c1',
            'removePush:c1',
            'cancelSubs:c1',
            'signOut:c1:loud',
            'removeAccount:c1',
            'forgetQuiet:c1',
            'emit:loginFailed',
          ]),
        );
      },
    );

    test(
      'a candidate is signed out loudly: no quiet-logout mark is left',
      () async {
        await failingAt('switchTo:c1');

        expect(host.calls, isNot(contains('signOut:c1:quiet')));
      },
    );

    test(
      'a failure before the switch puts the active account\'s state back',
      () async {
        await failingAt('switchTo:c1');

        expect(
          host.calls,
          containsAllInOrder(['tom:c1', 'removeAccount:c1', 'apply:a']),
        );
        expect(events(), [MultipleAccountLoginType.loginFailed]);
      },
    );

    test('a failure that touched no shared state restores nothing', () async {
      await failingAt('registerSubs:c1');

      expect(host.calls.where((c) => c.startsWith('apply:')), isEmpty);
    });
  });

  group('a rollback step that fails', () {
    test(
      'a sign-out that fails is reported and does not block the removal: the server session expires',
      () async {
        final session = await candidate();
        host.failing.addAll(['switchTo:c1', 'signOut:c1:loud']);
        await logIn(session);

        expect(session.state, LoginSessionState.disposed);
        expect(events(), [MultipleAccountLoginType.loginFailed]);
        expect(host.stored, isEmpty);
        expect(host.reports, contains('sign-out of c1 failed'));
      },
    );

    test(
      'a push removal that fails is reported and does not block the removal',
      () async {
        final session = await candidate();
        host.failing.addAll(['switchTo:c1', 'removePush:c1']);
        await logIn(session);

        expect(session.state, LoginSessionState.disposed);
        expect(host.stored, isEmpty);
        expect(host.reports, contains('push removal of c1 failed'));
      },
    );

    test(
      'subscriptions that cannot be cancelled are retried before the sign-out',
      () async {
        final session = await candidate();
        host.failing.addAll(['switchTo:c1', 'cancelSubs:c1']);
        await logIn(session);

        expect(session.state, LoginSessionState.cleanupFailed);
        expect(host.calls, isNot(contains('signOut:c1:loud')));

        host.failing.remove('cancelSubs:c1');
        await session.retryCleanup();

        expect(session.state, LoginSessionState.disposed);
        expect(
          host.calls,
          containsAllInOrder(['cancelSubs:c1', 'signOut:c1:loud']),
        );
      },
    );

    test(
      'a restore that fails after the removal is retried alone, the removal is not repeated',
      () async {
        final session = await candidate();
        host.failing.addAll(['switchTo:c1', 'apply:a']);
        await logIn(session);

        expect(session.state, LoginSessionState.cleanupFailed);
        expect(host.stored, isEmpty);

        host.failing.remove('apply:a');
        host.calls.clear();
        await session.retryCleanup();

        expect(host.calls, ['apply:a', 'forgetQuiet:c1']);
        expect(session.state, LoginSessionState.disposed);
      },
    );
  });

  group('a cleanup that fails', () {
    Future<LoginSession> stuck() async {
      final session = await candidate();
      host.failing.addAll(['switchTo:c1', 'removeAccount:c1']);
      await logIn(session);
      return session;
    }

    test(
      'ends in cleanupFailed and never reports loginFailed while the account is stored',
      () async {
        final session = await stuck();

        expect(session.state, LoginSessionState.cleanupFailed);
        expect(events(), [MultipleAccountLoginType.cleanupFailed]);
        expect(events(), isNot(contains(MultipleAccountLoginType.loginFailed)));
        expect(host.stored, {'c1'});
        expect(
          host.reports,
          contains('cleanup _Cleanup.removeAccount of c1 failed'),
        );
      },
    );

    test(
      'the failed step is retried, alone, and then the session is disposed',
      () async {
        final session = await stuck();
        host.calls.clear();
        host.failing.remove('removeAccount:c1');

        await session.retryCleanup();

        expect(host.calls, ['removeAccount:c1', 'apply:a', 'forgetQuiet:c1']);
        expect(session.state, LoginSessionState.disposed);
        expect(host.stored, isEmpty);
        expect(events(), [MultipleAccountLoginType.cleanupFailed]);
      },
    );

    test(
      'a removal that is still pending is not reported, and the step stays',
      () async {
        final session = await candidate();
        host.removalPending.add('removeAccount:c1');
        host.failing.add('switchTo:c1');
        await logIn(session);

        expect(session.state, LoginSessionState.cleanupFailed);
        expect(host.reports.where((r) => r.startsWith('cleanup ')), isEmpty);

        host.removalPending.clear();
        await session.retryCleanup();

        expect(session.state, LoginSessionState.disposed);
        expect(host.calls.where((c) => c == 'removeAccount:c1'), hasLength(2));
      },
    );

    test('another error in a cleanup step is still reported', () async {
      final session = await stuck();

      await session.retryCleanup();

      expect(host.reports.where((r) => r.startsWith('cleanup ')), hasLength(2));
    });

    test('a retry that fails again stays in cleanupFailed', () async {
      final session = await stuck();

      await session.retryCleanup();

      expect(session.state, LoginSessionState.cleanupFailed);
      expect(host.calls.where((c) => c == 'removeAccount:c1'), hasLength(2));
    });

    test('retrying does nothing in another state', () async {
      final session = await candidate();

      await session.retryCleanup();

      expect(session.state, LoginSessionState.created);
      expect(host.calls, ['createCandidate:c1']);
    });

    test(
      'a discard that fails keeps the storage reachable and is retried',
      () async {
        final session = await candidate();
        host.failing.addAll(['addAccount:c1', 'discardCandidate:c1']);
        await logIn(session);
        expect(session.state, LoginSessionState.cleanupFailed);

        host.failing.remove('discardCandidate:c1');
        await session.retryCleanup();

        expect(session.state, LoginSessionState.disposed);
        expect(
          host.calls.where((c) => c == 'discardCandidate:c1'),
          hasLength(2),
        );
      },
    );
  });

  group('the session that keeps its client (first login)', () {
    late LoginSession session;

    setUp(() {
      host.activeName = 'a';
      session = LoginSession.placeholder(host, host.clientOf('a'));
    });

    test('registers, sets up and reports firstLoggedIn', () async {
      await session.onLoggedIn(LoginState.loggedIn);

      expect(session.state, LoginSessionState.active);
      expect(host.calls, [
        'firstSyncDone',
        'addAccount:a',
        'tom:a',
        'federation:a',
        'activateCurrent',
        'reSyncContacts',
        'emit:firstLoggedIn',
      ]);
    });

    test(
      'a failure signs out quietly, logs out the last account and goes back to created',
      () async {
        host.failing.add('activateCurrent');

        await session.onLoggedIn(LoginState.loggedIn);

        expect(session.state, LoginSessionState.created);
        expect(
          host.calls,
          containsAllInOrder([
            'signOut:a:quiet',
            'logoutLast',
            'emit:loginFailed',
          ]),
        );
        expect(host.calls, isNot(contains('cancelSubs:a')));
        expect(host.calls, isNot(contains('forgetQuiet:a')));
      },
    );

    test(
      'a failure of ToM or federation keeps the account and is reported',
      () async {
        host.failing.addAll(['tom:a', 'federation:a']);

        await session.onLoggedIn(LoginState.loggedIn);

        expect(session.state, LoginSessionState.active);
        expect(events(), [MultipleAccountLoginType.firstLoggedIn]);
        expect(host.calls, isNot(contains('logoutLast')));
        expect(host.reports, hasLength(2));
      },
    );

    test('a failure of addAccount has no account to log out', () async {
      host.failing.add('addAccount:a');

      await session.onLoggedIn(LoginState.loggedIn);

      expect(host.calls, isNot(contains('logoutLast')));
      expect(session.state, LoginSessionState.created);
      expect(events(), [MultipleAccountLoginType.loginFailed]);
    });

    test('a logoutLast that fails is cleanupFailed, not loginFailed', () async {
      host.failing.addAll(['activateCurrent', 'logoutLast']);

      await session.onLoggedIn(LoginState.loggedIn);

      expect(session.state, LoginSessionState.cleanupFailed);
      expect(events(), [MultipleAccountLoginType.cleanupFailed]);
    });

    test('after a rollback the same session logs in again', () async {
      host.failing.add('activateCurrent');
      await session.onLoggedIn(LoginState.loggedIn);
      host.failing.clear();
      host.calls.clear();

      await session.onLoggedIn(LoginState.loggedIn);

      expect(session.state, LoginSessionState.active);
      expect(host.calls.last, 'emit:firstLoggedIn');
    });

    // The SDK reports `loggedIn` after it holds the session again, so the
    // client is logged in when the event arrives.
    Future<void> logOutThenLogInAgain() async {
      host.loggedIn.remove('a');
      host.streams['a']!.add(LoginState.loggedOut);
      await pumpEventQueue();
      host.loggedIn.add('a');
      host.calls.clear();
      await session.onLoggedIn(LoginState.loggedIn);
    }

    test('a new login after the account logged out runs again', () async {
      await session.onLoggedIn(LoginState.loggedIn);

      await logOutThenLogInAgain();

      expect(host.calls, contains('activateCurrent'));
      expect(session.state, LoginSessionState.active);
    });

    Future<void> expectNextLoginIgnored() async {
      host.calls.clear();

      await session.onLoggedIn(LoginState.loggedIn);

      expect(host.calls, isEmpty);
      expect(session.state, LoginSessionState.active);
    }

    test('the logout is forgotten once the next login is accepted', () async {
      await session.onLoggedIn(LoginState.loggedIn);
      await logOutThenLogInAgain();

      await expectNextLoginIgnored();
    });

    test(
      'a loggedIn after a soft logout is a repeat, not a new login',
      () async {
        await session.onLoggedIn(LoginState.loggedIn);
        host.streams['a']!.add(LoginState.softLoggedOut);
        await pumpEventQueue();

        await expectNextLoginIgnored();
      },
    );

    test('a login try is refused while the cleanup keeps failing', () async {
      host.failing.addAll(['activateCurrent', 'logoutLast']);
      await session.onLoggedIn(LoginState.loggedIn);
      await session.retryCleanup();
      expect(session.state, LoginSessionState.cleanupFailed);

      expect(() => session.trackLogin<void>(() async {}), throwsStateError);
      expect(session.state, LoginSessionState.cleanupFailed);

      host.failing.clear();
      await session.retryCleanup();
      await session.trackLogin<void>(() async {});
      expect(session.state, LoginSessionState.loggingIn);
    });

    test(
      'a repeated login event of a logged-in account does nothing',
      () async {
        await session.onLoggedIn(LoginState.loggedIn);

        await expectNextLoginIgnored();
      },
    );

    test(
      'disposing it does nothing: the client is not the session\'s to throw away',
      () async {
        await session.dispose();

        expect(host.calls, isEmpty);
        expect(session.state, LoginSessionState.created);
      },
    );
  });

  group('disposing', () {
    test(
      'waits for a creation that is going on, then discards: no leak',
      () async {
        host.gates['createCandidate:c1'] = Completer<void>();
        final session = LoginSession.candidate(host);
        final disposed = session.dispose();
        await pumpEventQueue();
        expect(host.calls, ['createCandidate:c1']);

        host.gates['createCandidate:c1']!.complete();
        await disposed;

        expect(host.calls, [
          'createCandidate:c1',
          'removePush:c1',
          'cancelSubs:c1',
          'signOut:c1:loud',
          'discardCandidate:c1',
          'forgetQuiet:c1',
        ]);
        expect(session.state, LoginSessionState.disposed);
        expect(host.pending, isNull);
      },
    );

    test('a candidate that never logged in is discarded', () async {
      final session = await candidate();

      await session.dispose();

      expect(host.calls, contains('discardCandidate:c1'));
      expect(session.state, LoginSessionState.disposed);
    });

    test('waits for every login that is going on, not only the last', () async {
      final session = await candidate();
      final first = Completer<void>();
      final second = Completer<void>();
      unawaited(session.trackLogin<void>(() => first.future));
      unawaited(session.trackLogin<void>(() => second.future));

      var disposed = false;
      final done = session.dispose().then((_) => disposed = true);
      second.complete();
      await pumpEventQueue();
      expect(disposed, isFalse);

      first.complete();
      host.loggedIn.add('c1');
      await done;

      expect(host.calls, isNot(contains('discardCandidate:c1')));
    });

    test('is idempotent, also when asked twice at once', () async {
      final session = await candidate();

      await Future.wait([session.dispose(), session.dispose()]);
      await session.dispose();

      expect(host.calls.where((c) => c == 'discardCandidate:c1'), hasLength(1));
    });

    test(
      'waits for a login that is going on and discards when it failed',
      () async {
        final session = await candidate();
        final login = Completer<void>();
        unawaited(
          session.trackLogin<void>(() => login.future).catchError((_) {}),
        );

        final disposed = session.dispose();
        await pumpEventQueue();
        expect(host.calls, ['createCandidate:c1']);

        login.completeError(StateError('wrong password'));
        await disposed;

        expect(host.calls, contains('discardCandidate:c1'));
      },
    );

    test(
      'a login started after the disposal was requested is refused',
      () async {
        final session = await candidate();
        final login = Completer<void>();
        unawaited(
          session.trackLogin<void>(() => login.future).catchError((_) {}),
        );
        final disposed = session.dispose();
        var started = false;

        expect(
          () => session.trackLogin<void>(() async => started = true),
          throwsStateError,
        );
        login.completeError(StateError('wrong password'));
        await disposed;

        expect(started, isFalse);
        expect(host.calls, contains('discardCandidate:c1'));
      },
    );

    test(
      'keeps a client whose login worked while the user was leaving',
      () async {
        final session = await candidate();
        final login = Completer<void>();
        unawaited(session.trackLogin<void>(() => login.future));

        final disposed = session.dispose();
        host.loggedIn.add('c1');
        login.complete();
        await disposed;
        host.streams['c1']!.add(LoginState.loggedIn);
        await pumpEventQueue();

        expect(host.calls, isNot(contains('discardCandidate:c1')));
        expect(session.state, LoginSessionState.active);
      },
    );

    test(
      'waits for a registration that is going on and then keeps the account',
      () async {
        host.gates['tom:c1'] = Completer<void>();
        final session = await candidate();
        host.logIn('c1');
        await pumpEventQueue();
        expect(session.state, LoginSessionState.registering);

        final disposed = session.dispose();
        await pumpEventQueue();
        expect(host.calls, isNot(contains('discardCandidate:c1')));

        host.gates['tom:c1']!.complete();
        await disposed;

        expect(session.state, LoginSessionState.active);
        expect(host.calls, isNot(contains('discardCandidate:c1')));
        expect(host.calls, isNot(contains('removeAccount:c1')));
      },
    );

    test(
      'a registration that fails while the user leaves ends rolled back, once',
      () async {
        host.gates['registerSubs:c1'] = Completer<void>();
        host.failing.add('registerSubs:c1');
        final session = await candidate();
        host.logIn('c1');
        await pumpEventQueue();

        final disposed = session.dispose();
        host.gates['registerSubs:c1']!.complete();
        await disposed;

        expect(session.state, LoginSessionState.disposed);
        expect(host.calls.where((c) => c == 'removeAccount:c1'), hasLength(1));
        expect(events(), [MultipleAccountLoginType.loginFailed]);
      },
    );

    test('an account that became active is left alone', () async {
      final session = await candidate();
      await logIn(session);
      host.calls.clear();

      await session.dispose();

      expect(host.calls, isEmpty);
    });

    test('in cleanupFailed it retries the cleanup', () async {
      final session = await candidate();
      host.failing.addAll(['switchTo:c1', 'removeAccount:c1']);
      await logIn(session);
      host.failing.remove('removeAccount:c1');

      await session.dispose();

      expect(session.state, LoginSessionState.disposed);
      expect(host.stored, isEmpty);
    });

    test(
      'a discard that fails ends in cleanupFailed and is reported',
      () async {
        final session = await candidate();
        host.failing.add('discardCandidate:c1');

        await session.dispose();

        expect(session.state, LoginSessionState.cleanupFailed);
        expect(
          host.reports,
          contains(contains('discardCandidate of c1 failed')),
        );
      },
    );

    test('a failed disposal can be retried by disposing again', () async {
      final session = await candidate();
      host.failing.add('discardCandidate:c1');
      await session.dispose();
      host.failing.remove('discardCandidate:c1');

      await session.dispose();

      expect(session.state, LoginSessionState.disposed);
    });
  });

  group('the set-ups of an active account that failed', () {
    Future<LoginSession> failedAt(String step) async {
      final session = await candidate();
      host.failing.add(step);
      await logIn(session);
      host.failing.clear();
      host.calls.clear();
      return session;
    }

    test('a ToM set-up waits until its account is the active one', () async {
      final session = await failedAt('tom:c1');
      host.activeName = 'a';

      await session.retryCleanup();

      expect(host.calls, isNot(contains('tom:c1')));
      expect(session.needsRetry, isTrue);

      host.activeName = 'c1';
      await session.retryCleanup();

      expect(host.calls, contains('tom:c1'));
      expect(session.needsRetry, isFalse);
    });

    test(
      'a set-up that does not write the active state runs at once',
      () async {
        final session = await failedAt('recoveryKey:c1');
        host.activeName = 'a';

        await session.retryCleanup();

        expect(host.calls, contains('recoveryKey:c1'));
        expect(session.needsRetry, isFalse);
      },
    );

    test('they are dropped when the account is gone', () async {
      final session = await failedAt('recoveryKey:c1');
      host.stored.remove('c1');

      await session.retryCleanup();

      expect(host.calls, isEmpty);
      expect(session.needsRetry, isFalse);
    });
  });

  group('the guards of a session', () {
    test('the client of a session that is not created yet is an error', () {
      host.gates['createCandidate:c1'] = Completer<void>();
      final session = LoginSession.candidate(host);

      expect(() => session.client, throwsStateError);
    });

    test('a login cannot start once the session is active', () async {
      final session = await candidate();
      await logIn(session);

      expect(() => session.trackLogin(() async {}), throwsStateError);
    });

    test(
      'a listener of the event that throws does not undo the login',
      () async {
        final session = await candidate();
        host.failing.add('emit');

        await logIn(session);

        expect(session.state, LoginSessionState.active);
        expect(host.stored, {'c1'});
        expect(host.reports, contains('event of c1 failed'));
      },
    );

    test('nor does it stop a rollback', () async {
      host.failing.addAll(['emit', 'switchTo:c1']);
      final session = await candidate();

      await logIn(session);

      expect(session.state, LoginSessionState.disposed);
      expect(host.stored, isEmpty);
    });
  });
}
