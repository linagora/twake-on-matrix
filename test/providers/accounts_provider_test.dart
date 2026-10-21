import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/data/account/sources/pending_removals_source.dart';
import 'package:twake_chat/domain/account/entities/account.dart';
import 'package:twake_chat/domain/account/entities/accounts_state.dart';
import 'package:twake_chat/domain/account/entities/switch_ticket.dart';
import 'package:twake_chat/domain/account/exceptions/account_exception.dart';
import 'package:twake_chat/providers/account_repository_provider.dart';
import 'package:twake_chat/providers/accounts_provider.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/providers/login_candidate_provider.dart';
import 'package:twake_chat/utils/famedlysdk_store.dart';

import '../data/account/fakes.dart';

void main() {
  late ProviderContainer container;
  late FakeAccountClient a;
  late FakeAccountClient b;
  late FakeAccountClient c;
  late FakeAccountClientDataSource dataSource;

  /// Builds a container whose repository already adopted [clients], as
  /// `MatrixState.initState` does before anything reads the state.
  void boot(
    List<FakeAccountClient> clients, {
    String? persistedUserId,
    Set<String> pending = const {},
  }) {
    dataSource = FakeAccountClientDataSource();
    container = ProviderContainer(
      overrides: [
        accountClientDataSourceProvider.overrideWithValue(dataSource),
        if (persistedUserId != null)
          bootPersistedActiveUserIdProvider.overrideWithValue(persistedUserId),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(accountRepositoryProvider)
        .adopt(clients, pendingRemovals: pending);
  }

  AccountsState state() => container.read(accountsProvider);
  Accounts notifier() => container.read(accountsProvider.notifier);
  List<AccountsState> record() {
    final seen = <AccountsState>[];
    container.listen(accountsProvider, (_, next) => seen.add(next));
    return seen;
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    a = FakeAccountClient('a', userID: '@a:s');
    b = FakeAccountClient('b', userID: '@b:s');
    c = FakeAccountClient('c', userID: '@c:s');
  });

  group('boot', () {
    test('logged-in boot: the first account is active', () {
      boot([a, b]);
      expect(state(), isA<Active>());
      expect((state() as Active).activeId, 'a');
      expect(container.read(activeMatrixClientProvider), same(a));
      expect(container.read(accountClientsProvider), [a, b]);
    });

    test(
      'logged-out boot: NoAccount, no active client, placeholder offered',
      () {
        final placeholder = FakeAccountClient('p', logged: false);
        boot([placeholder]);
        expect(state(), const NoAccount(candidateId: 'p'));
        expect(container.read(activeMatrixClientProvider), isNull);
        expect(container.read(loginCandidateProvider), same(placeholder));
        expect(container.read(accountClientsProvider), [placeholder]);
      },
    );

    test('boot with every account waiting for its removal lists them', () {
      boot([a, b], pending: {'a', 'b'});
      expect(state(), isA<NoAccount>());
      expect(container.read(activeMatrixClientProvider), isNull);
      expect(container.read(accountClientsProvider), [a, b]);
    });

    test('empty list: NoAccount without candidate', () {
      boot([]);
      expect(state(), const NoAccount());
      expect(container.read(accountClientsProvider), isEmpty);
      expect(container.read(loginCandidateProvider), isNull);
    });

    test(
      'accounts that wait for their removal are never the login candidate',
      () {
        boot([a, b], pending: {'a', 'b'});
        expect(container.read(loginCandidateProvider), isNull);
      },
    );

    test('the last logged-out account is the login candidate', () {
      boot([a]);
      notifier().logoutLast();
      expect(state(), isA<LastLoggedOut>());
      expect(container.read(loginCandidateProvider), same(a));
    });

    test('the persisted account is active from the first read', () {
      boot([a, b], persistedUserId: '@b:s');
      expect((state() as Active).activeId, 'b');
      expect(container.read(activeMatrixClientProvider), same(b));
    });

    test('a persisted account that is logged out falls back to the first '
        'logged-in one', () {
      final loggedOut = FakeAccountClient('x', userID: '@x:s', logged: false);
      boot([a, loggedOut], persistedUserId: '@x:s');
      expect((state() as Active).activeId, 'a');
    });

    test('a persisted account that is not registered any more falls back to '
        'the first one', () {
      boot([a, b], persistedUserId: '@gone:s');
      expect((state() as Active).activeId, 'a');
    });

    test('a logged-out first account is skipped even when persisted', () {
      final loggedOut = FakeAccountClient('x', userID: '@x:s', logged: false);
      boot([loggedOut, b], persistedUserId: '@x:s');
      expect((state() as Active).activeId, 'b');
    });

    test('nothing persisted: the first account is active', () {
      boot([a, b]);
      expect((state() as Active).activeId, 'a');
    });

    test('the state survives with no listener (keepAlive)', () async {
      boot([a, b]);
      container.read(accountsProvider);
      await container.pump();
      expect(container.exists(accountsProvider), isTrue);
    });
  });

  group('switchTo', () {
    setUp(() => boot([a, b]));

    test(
      'without a handler it emits Switching then Active, once each',
      () async {
        final seen = record();
        await notifier().switchTo('b');
        expect(seen, [
          isA<Switching>(),
          isA<Active>().having((s) => s.activeId, 'activeId', 'b'),
        ]);
      },
    );

    test('the active client is still the old one while switching', () async {
      final handlerStarted = Completer<void>();
      final release = Completer<void>();
      final dispose = notifier().registerSwitchHandler();
      addTearDown(dispose);
      container.listen(accountsProvider, (_, next) async {
        if (next is Switching) {
          handlerStarted.complete();
          await release.future;
          notifier().completeSwitch(next.ticket);
        }
      });

      final done = notifier().switchTo('b');
      await handlerStarted.future;

      expect(state(), isA<Switching>());
      expect(container.read(activeMatrixClientProvider), same(a));

      release.complete();
      await done;
      expect(container.read(activeMatrixClientProvider), same(b));
    });

    test('the Switching state carries the number of its switch', () async {
      boot([a, b, c]);
      final dispose = notifier().registerSwitchHandler();
      addTearDown(dispose);

      final first = notifier().switchTo('b');
      final firstResult = expectLater(
        first,
        throwsA(isA<SwitchSupersededException>()),
      );
      await pumpEventQueue();
      final firstSeq = (state() as Switching).seq;
      expect(firstSeq, notifier().switchSeq);

      final second = notifier().switchTo('c');
      await pumpEventQueue();
      expect((state() as Switching).seq, firstSeq + 1);
      await firstResult;

      notifier().completeSwitch(SwitchTicket(to: 'c', seq: firstSeq));
      expect(state(), isA<Switching>());

      notifier().completeSwitch(
        SwitchTicket(to: 'c', seq: (state() as Switching).seq),
      );
      await second;
      expect((state() as Active).activeId, 'c');
    });

    test(
      'with a handler the future ends only when the handler completes',
      () async {
        final dispose = notifier().registerSwitchHandler();
        addTearDown(dispose);
        var completed = false;
        final future = notifier().switchTo('b').then((_) => completed = true);

        await pumpEventQueue();
        expect(completed, isFalse);

        notifier().completeSwitch(
          SwitchTicket(to: 'b', seq: notifier().switchSeq),
        );
        await future;
        expect(completed, isTrue);
        expect((state() as Active).activeId, 'b');
      },
    );

    test(
      'a failed switch returns to the old account and rethrows (P7)',
      () async {
        final dispose = notifier().registerSwitchHandler();
        addTearDown(dispose);
        final seen = record();
        final future = notifier().switchTo('b');
        await pumpEventQueue();

        notifier().failSwitch(
          SwitchTicket(to: 'b', seq: notifier().switchSeq),
          StateError('effects failed'),
        );

        await expectLater(future, throwsStateError);
        expect(seen.last, isA<Active>());
        expect((state() as Active).activeId, 'a');
        expect(container.read(activeMatrixClientProvider), same(a));
      },
    );

    test('a second switch supersedes the first', () async {
      boot([a, b, c]);
      final dispose = notifier().registerSwitchHandler();
      addTearDown(dispose);

      final first = notifier().switchTo('b');
      final firstResult = expectLater(
        first,
        throwsA(isA<SwitchSupersededException>()),
      );
      await pumpEventQueue();
      final firstSeq = notifier().switchSeq;
      final second = notifier().switchTo('c');
      await pumpEventQueue();

      await firstResult;
      notifier().completeSwitch(
        SwitchTicket(to: 'b', seq: firstSeq),
      ); // stale: ignored
      expect(state(), isA<Switching>());
      notifier().completeSwitch(
        SwitchTicket(to: 'c', seq: notifier().switchSeq),
      );
      await second;
      expect((state() as Active).activeId, 'c');
    });

    test(
      'a stale handler cannot end a newer switch to the same account',
      () async {
        final dispose = notifier().registerSwitchHandler();
        addTearDown(dispose);
        final first = expectLater(
          notifier().switchTo('b'),
          throwsA(isA<SwitchSupersededException>()),
        );
        await pumpEventQueue();
        final firstSeq = notifier().switchSeq;
        await notifier().switchTo('a');
        final second = notifier().switchTo('b');
        await pumpEventQueue();
        await first;

        notifier().completeSwitch(SwitchTicket(to: 'b', seq: firstSeq));
        notifier().failSwitch(
          SwitchTicket(to: 'b', seq: firstSeq),
          StateError('stale'),
        );
        expect(state(), isA<Switching>());

        notifier().completeSwitch(
          SwitchTicket(to: 'b', seq: notifier().switchSeq),
        );
        await second;
        expect((state() as Active).activeId, 'b');
      },
    );

    test('asking again for the switch that is running joins it', () async {
      final dispose = notifier().registerSwitchHandler();
      addTearDown(dispose);
      final first = notifier().switchTo('b');
      await pumpEventQueue();
      final seq = notifier().switchSeq;
      final again = notifier().switchTo('b');
      await pumpEventQueue();

      expect(notifier().switchSeq, seq);
      notifier().completeSwitch(SwitchTicket(to: 'b', seq: seq));
      await first;
      await again;
      expect((state() as Active).activeId, 'b');
    });

    test(
      'a handler that fails at once ends the switch with its error',
      () async {
        final dispose = notifier().registerSwitchHandler();
        addTearDown(dispose);
        container.listen(accountsProvider, (_, next) {
          if (next is Switching) {
            notifier().failSwitch(next.ticket, StateError('now'));
          }
        });

        await expectLater(notifier().switchTo('b'), throwsStateError);
        expect((state() as Active).activeId, 'a');
      },
    );

    test('whenSwitchSettled waits for the running switch', () async {
      final dispose = notifier().registerSwitchHandler();
      addTearDown(dispose);
      final switching = notifier().switchTo('b');
      await pumpEventQueue();
      var settled = false;
      final waiting = notifier().whenSwitchSettled().then(
        (_) => settled = true,
      );

      await pumpEventQueue();
      expect(settled, isFalse);
      notifier().completeSwitch(
        SwitchTicket(to: 'b', seq: notifier().switchSeq),
      );
      await switching;
      await waiting;
      expect(settled, isTrue);
    });

    test(
      'a removal waits for the add that is writing (no lost update)',
      () async {
        boot([a]);
        final candidate = await container
            .read(accountRepositoryProvider)
            .createCandidate();
        container
            .read(accountClientRegistryProvider)
            .add(FakeAccountClient(candidate.id, userID: '@n:s'));

        final adding = notifier().addAccount(candidate.id);
        final removing = notifier().removeAccount('a');
        await Future.wait([adding, removing]);

        expect(state().accounts.map((x) => x.id), [candidate.id]);
        expect((state() as Active).activeId, candidate.id);
      },
    );

    test('switching to the active account emits nothing', () async {
      final seen = record();
      await notifier().switchTo('a');
      expect(seen, isEmpty);
    });

    test('switching to an unknown account throws and emits nothing', () async {
      final seen = record();
      await expectLater(
        notifier().switchTo('x'),
        throwsA(isA<UnknownAccountException>()),
      );
      expect(seen, isEmpty);
    });
  });

  group('removeAccount (D4, P2, P6)', () {
    test(
      'removing a non-active account keeps the active one, one emission',
      () async {
        boot([a, b, c]);
        await notifier().switchTo('c');
        final seen = record();

        await notifier().removeAccount('a');

        expect(seen, hasLength(1));
        expect((state() as Active).activeId, 'c');
        expect(container.read(accountClientsProvider), [b, c]);
        expect(container.read(activeMatrixClientProvider), same(c));
      },
    );

    test(
      'removing the active account picks the follower in one emission',
      () async {
        boot([a, b, c]);
        final seen = record();

        await notifier().removeAccount('a');

        expect(seen, hasLength(1));
        expect((state() as Active).activeId, 'b');
        expect(container.read(activeMatrixClientProvider), same(b));
      },
    );

    test('is rejected while switching, state and store untouched', () async {
      boot([a, b]);
      final dispose = notifier().registerSwitchHandler();
      addTearDown(dispose);
      unawaited(notifier().switchTo('b').catchError((_) {}));
      await pumpEventQueue();

      await expectLater(
        notifier().removeAccount('b'),
        throwsA(isA<InvalidAccountTransitionException>()),
      );
      expect(state(), isA<Switching>());
      expect(container.read(accountClientsProvider), [a, b]);
    });

    test('the only account must go through logoutLast', () async {
      boot([a]);
      await expectLater(
        notifier().removeAccount('a'),
        throwsA(isA<InvalidAccountTransitionException>()),
      );
      expect((state() as Active).activeId, 'a');
    });
  });

  group('an account whose removal failed', () {
    test(
      'a non-active account is listed as unavailable, the active one stays',
      () async {
        boot([a, b]);
        final seen = record();

        await notifier().holdRemoval('b');

        expect(seen, hasLength(1));
        final held = state() as Active;
        expect(held.activeId, 'a');
        expect(held.accounts.last.status, AccountStatus.unavailable);
        expect(container.read(accountClientsProvider), [a, b]);
      },
    );

    test('the active account hands over in one emission', () async {
      boot([a, b]);
      final seen = record();

      await notifier().holdRemoval('a');

      expect(seen, hasLength(1));
      expect((state() as Active).activeId, 'b');
      expect(container.read(activeMatrixClientProvider), same(b));
    });

    test(
      'with no logged-in survivor nobody is logged in and it stays listed',
      () async {
        boot([a, b]);
        await notifier().holdRemoval('b');

        await notifier().holdRemoval('a');

        expect(state(), isA<NoAccount>());
        expect(state().accounts.map((x) => x.id), ['a', 'b']);
        expect(container.read(activeMatrixClientProvider), isNull);
      },
    );

    test('holding again changes nothing, so a retry is safe', () async {
      boot([a, b]);
      await notifier().holdRemoval('b');
      final seen = record();

      await notifier().holdRemoval('b');

      expect(seen, isEmpty);
    });

    test(
      'removing the active account with only unavailable survivors logs nobody in',
      () async {
        boot([a, b]);
        await notifier().holdRemoval('b');

        await notifier().removeAccount('a');

        expect(state(), isA<NoAccount>());
        expect(state().accounts.map((x) => x.id), ['b']);
        expect(container.read(activeMatrixClientProvider), isNull);
      },
    );

    test('the record that survives a restart is written on its own', () async {
      boot([a, b]);
      await notifier().holdRemoval('b');
      expect(await PendingRemovalsSource(Store()).read(), isEmpty);

      await notifier().recordPendingRemoval('b');

      expect(await PendingRemovalsSource(Store()).read(), {'b'});
    });

    test(
      'a boot where every account waits for its removal retains them and removes them',
      () async {
        dataSource = FakeAccountClientDataSource();
        container = ProviderContainer(
          overrides: [
            accountClientDataSourceProvider.overrideWithValue(dataSource),
          ],
        );
        addTearDown(container.dispose);
        container
            .read(accountRepositoryProvider)
            .adopt([a, b], pendingRemovals: {'a', 'b'});

        expect(state(), isA<NoAccount>());
        expect(state().accounts.map((x) => x.id), ['a', 'b']);

        await notifier().removeAccount('a');
        await notifier().removeAccount('b');

        expect(state(), const NoAccount());
        expect(dataSource.calls, contains('delete:a'));
        expect(dataSource.calls, contains('delete:b'));
      },
    );
  });

  group('logoutLast and login again', () {
    test('the last account stays listed, with no active client', () {
      boot([a]);
      final seen = record();

      notifier().logoutLast();

      expect(seen, hasLength(1));
      expect(state(), isA<LastLoggedOut>());
      expect(container.read(activeMatrixClientProvider), isNull);
      expect(container.read(accountClientsProvider), [a]);
    });

    test('accounts waiting for their removal stay listed, and the new account '
        'can log in again', () async {
      final waiting = FakeAccountClient('w', userID: '@w:s', logged: false);
      boot([waiting], pending: {'w'});
      final candidate = await container
          .read(accountRepositoryProvider)
          .createCandidate();
      container
          .read(accountClientRegistryProvider)
          .add(FakeAccountClient(candidate.id, userID: '@n:s'));
      await notifier().addAccount(candidate.id);
      expect((state() as Active).accounts, hasLength(2));

      notifier().logoutLast();

      final out = state() as NoAccount;
      expect(out.candidateId, candidate.id);
      expect(out.accounts.map((x) => x.id), ['w']);
      expect(out.accounts.single.status, AccountStatus.unavailable);

      await notifier().addAccount(candidate.id);

      expect((state() as Active).activeId, candidate.id);
    });

    test('logging in again gives Active', () async {
      boot([a]);
      notifier().logoutLast();

      await notifier().addAccount('a');

      expect((state() as Active).activeId, 'a');
      expect(container.read(activeMatrixClientProvider), same(a));
    });

    test('the placeholder becomes the first account on login', () async {
      final placeholder = FakeAccountClient('p', logged: false);
      boot([placeholder]);
      expect(state(), isA<NoAccount>());

      // The placeholder logs in: the SDK client now reports a user id.
      final loggedIn = FakeAccountClient('p', userID: '@p:s');
      container.read(accountClientRegistryProvider).add(loggedIn);
      await notifier().addAccount('p');

      expect((state() as Active).activeId, 'p');
      expect(container.read(activeMatrixClientProvider), same(loggedIn));
    });
  });

  group('addAccount', () {
    test('a candidate is listed only after it is added', () async {
      boot([a]);
      final candidate = await container
          .read(accountRepositoryProvider)
          .createCandidate();
      container.read(pendingLoginCandidateProvider.notifier).set(candidate.id);
      expect(container.read(accountClientsProvider), [a]);
      expect(container.read(loginCandidateProvider), isNotNull);

      container
          .read(accountClientRegistryProvider)
          .add(FakeAccountClient(candidate.id, userID: '@n:s'));
      await notifier().addAccount(candidate.id);

      expect(container.read(accountClientsProvider).map((c) => c.clientName), [
        'a',
        candidate.id,
      ]);
      expect((state() as Active).activeId, 'a');
    });

    test('a repeated login event for a listed account does nothing', () async {
      boot([a, b]);
      final seen = record();
      await notifier().addAccount('a');
      expect(seen, isEmpty);
    });

    test('a failing store write leaves the state unchanged (R5)', () async {
      boot([a]);
      final candidate = await container
          .read(accountRepositoryProvider)
          .createCandidate();
      container
          .read(accountClientRegistryProvider)
          .add(FakeAccountClient(candidate.id, userID: '@n:s'));
      dataSource.failAddName = true;
      final seen = record();

      await expectLater(
        notifier().addAccount(candidate.id),
        throwsA(isA<StateError>()),
      );

      expect(seen, isEmpty);
      expect(container.read(accountClientsProvider), [a]);
    });

    test('an unknown id throws and emits nothing', () async {
      boot([a]);
      final seen = record();
      await expectLater(
        notifier().addAccount('missing'),
        throwsA(isA<UnknownAccountException>()),
      );
      expect(seen, isEmpty);
    });
  });
}
