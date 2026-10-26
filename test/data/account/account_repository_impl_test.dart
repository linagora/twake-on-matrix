import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/data/account/repositories/account_repository_impl.dart';
import 'package:twake_chat/data/account/repositories/client_account_boot_port.dart';
import 'package:twake_chat/data/account/sources/account_client_registry.dart';
import 'package:twake_chat/data/account/sources/pending_removals_source.dart';
import 'package:twake_chat/data/account/sources/persisted_active_account_source.dart';
import 'package:twake_chat/domain/account/entities/account.dart';
import 'package:twake_chat/domain/account/exceptions/account_exception.dart';
import 'package:twake_chat/utils/famedlysdk_store.dart';

import 'fakes.dart';

void main() {
  late FakeAccountClientDataSource dataSource;
  late AccountClientRegistry registry;
  late AccountRepositoryImpl repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dataSource = FakeAccountClientDataSource();
    registry = AccountClientRegistry();
    repository = AccountRepositoryImpl(
      dataSource: dataSource,
      persistedActiveAccount: PersistedActiveAccountSource(Store()),
      pendingRemovals: PendingRemovalsSource(Store()),
      pendingPushRemovals: PendingRemovalsSource(
        Store(),
        storeKey: PendingRemovalsSource.pushKey,
      ),
      pendingCandidateDiscards: PendingRemovalsSource(
        Store(),
        storeKey: PendingRemovalsSource.candidateKey,
      ),
      registry: registry,
      clientNameBuilder: () => 'new-client',
    );
  });

  group('pending pusher deletions', () {
    test('are kept across a new repository, and cleared once', () async {
      await repository.markPushRemovalPending('a');
      await repository.markPushRemovalPending('b');

      expect(await repository.pendingPushRemovals(), {'a', 'b'});

      await repository.clearPushRemovalPending('a');
      await repository.clearPushRemovalPending('a');

      expect(await repository.pendingPushRemovals(), {'b'});
    });

    test(
      'a change before the first read keeps what a past session saved',
      () async {
        await repository.markPushRemovalPending('a');
        await repository.markCandidateDiscardPending('c');
        final restarted = _newRepository(dataSource, registry);

        await restarted.markPushRemovalPending('b');
        await restarted.markCandidateDiscardPending('d');

        expect(await restarted.pendingPushRemovals(), {'a', 'b'});
        expect(await restarted.pendingCandidateDiscards(), {'c', 'd'});
      },
    );

    test('a clear before the first read removes a saved id', () async {
      await repository.markPushRemovalPending('a');
      await repository.markCandidateDiscardPending('c');
      final restarted = _newRepository(dataSource, registry);

      await restarted.clearPushRemovalPending('a');
      await restarted.clearCandidateDiscardPending('c');

      expect(await restarted.pendingPushRemovals(), isEmpty);
      expect(await restarted.pendingCandidateDiscards(), isEmpty);
    });

    test('do not mix with the pending account removals', () async {
      await repository.markPushRemovalPending('a');

      expect(await PendingRemovalsSource(Store()).read(), isEmpty);
    });
  });

  group('pendingRemovalIds', () {
    test('reads what markRemovalPending recorded', () async {
      registry.add(FakeAccountClient('a'));
      repository.adopt([registry['a']!], pendingRemovals: const {});
      await repository.markRemovalPending('a');

      expect(await repository.pendingRemovalIds(), {'a'});
    });

    test('is empty when nothing was recorded', () async {
      expect(await repository.pendingRemovalIds(), isEmpty);
    });
  });

  group('ClientAccountBootPort', () {
    test('adopts the boot clients into the repository', () {
      final a = FakeAccountClient('a', userID: '@a:s');
      final port = ClientAccountBootPort(repository: repository, clients: [a]);

      expect(port.adopt(pendingRemovals: const {}), const [
        Account(id: 'a', userId: '@a:s', status: AccountStatus.loggedIn),
      ]);
      expect(registry['a'], same(a));
    });
  });

  group('adopt', () {
    test('maps clients to accounts in store order and fills the registry', () {
      final a = FakeAccountClient('a', userID: '@a:s');
      final p = FakeAccountClient('p', logged: false);

      final accounts = repository.adopt([a, p], pendingRemovals: const {});

      expect(accounts, [
        const Account(id: 'a', userId: '@a:s', status: AccountStatus.loggedIn),
        const Account(id: 'p', status: AccountStatus.unavailable),
      ]);
      expect(registry['a'], same(a));
      expect(registry['p'], same(p));
    });
  });

  group('a logged-out client beside others is owed a removal', () {
    test('adopt lists it as unavailable instead of deleting it', () {
      final accounts = repository.adopt([
        FakeAccountClient('a', userID: '@a:s'),
        FakeAccountClient('p', logged: false),
      ], pendingRemovals: const {});

      expect(accounts.map((x) => x.status), [
        AccountStatus.loggedIn,
        AccountStatus.unavailable,
      ]);
      expect(dataSource.calls, isEmpty);
    });

    test('alone it is only logged out (the placeholder of the next login)', () {
      final accounts = repository.adopt([
        FakeAccountClient('p', logged: false),
      ], pendingRemovals: const {});

      expect(accounts.single.status, AccountStatus.loggedOut);
    });
  });

  group('pending account removals survive an unreadable boot', () {
    final a = FakeAccountClient('a', userID: '@a:s');
    final b = FakeAccountClient('b', userID: '@b:s');

    test('marking a removal keeps the ones the last session saved', () async {
      await PendingRemovalsSource(Store()).write({'b'});
      // The boot read of the persisted ids failed: nothing is passed in.
      repository.adopt([a, b], pendingRemovals: const {});

      await repository.markRemovalPending('a');

      expect(await repository.pendingRemovalIds(), {'a', 'b'});
    });

    test('removing an account keeps the other persisted ones', () async {
      await PendingRemovalsSource(Store()).write({'a', 'b'});
      repository.adopt([a, b], pendingRemovals: const {'a'});

      await repository.removeAccount('a');

      expect(await repository.pendingRemovalIds(), {'b'});
    });
  });

  group('createCandidate / addAccount', () {
    test('a candidate is unlogged, registered and not yet persisted', () async {
      final candidate = await repository.createCandidate();

      expect(candidate.id, 'new-client');
      expect(candidate.status, AccountStatus.loggedOut);
      expect(registry['new-client'], isNotNull);
      expect(dataSource.calls, ['create:new-client']);
    });

    test('addAccount stores the name once', () async {
      await repository.createCandidate();
      const account = Account(
        id: 'new-client',
        userId: '@n:s',
        status: AccountStatus.loggedIn,
      );

      await repository.addAccount(account);
      await repository.addAccount(account);

      expect(dataSource.calls.where((c) => c.startsWith('add:')), [
        'add:new-client',
      ]);
    });

    test('an account loaded from the store is not added again', () async {
      repository.adopt([
        FakeAccountClient('a', userID: '@a:s'),
      ], pendingRemovals: const {});

      await repository.addAccount(
        const Account(id: 'a', status: AccountStatus.loggedIn),
      );

      expect(dataSource.calls.where((c) => c.startsWith('add:')), isEmpty);
    });

    test('addAccount of an unknown id throws', () async {
      await expectLater(
        repository.addAccount(
          const Account(id: 'x', status: AccountStatus.loggedIn),
        ),
        throwsA(isA<UnknownAccountException>()),
      );
      expect(dataSource.calls, isEmpty);
    });
  });

  group('removeAccount', () {
    setUp(() async {
      repository.adopt([
        FakeAccountClient('a', userID: '@a:s'),
        FakeAccountClient('b', userID: '@b:s'),
      ], pendingRemovals: const {});
      dataSource.calls.clear();
    });

    test(
      'deletes the storage first, then drops the name and the client',
      () async {
        await repository.removeAccount('b');

        expect(dataSource.calls, ['delete:b', 'remove:b']);
        expect(registry['b'], isNull);
        expect(registry['a'], isNotNull);
      },
    );

    test(
      'a storage that cannot be deleted keeps the account, and can be retried',
      () async {
        dataSource.failDelete = true;

        await expectLater(
          repository.removeAccount('b'),
          throwsA(isA<StateError>()),
        );

        expect(dataSource.calls, ['delete:b']);
        expect(registry['b'], isNotNull);
        expect(repository.registeredAccounts().map((a) => a.id), ['a', 'b']);

        dataSource.failDelete = false;
        await repository.removeAccount('b');

        expect(dataSource.calls, ['delete:b', 'delete:b', 'remove:b']);
        expect(registry['b'], isNull);
      },
    );

    test(
      'a name that cannot be removed does not delete the storage twice',
      () async {
        dataSource.failRemoveName = true;

        await expectLater(
          repository.removeAccount('b'),
          throwsA(isA<StateError>()),
        );
        expect(registry['b'], isNotNull);

        dataSource.failRemoveName = false;
        await repository.removeAccount('b');

        expect(dataSource.calls, ['delete:b', 'remove:b', 'remove:b']);
        expect(registry['b'], isNull);
      },
    );

    test(
      'a candidate that was never stored must be discarded instead',
      () async {
        await repository.createCandidate();
        dataSource.calls.clear();

        await expectLater(
          repository.removeAccount('new-client'),
          throwsA(isA<NotStoredAccountException>()),
        );
        expect(dataSource.calls, isEmpty);
        expect(registry['new-client'], isNotNull);
      },
    );

    test('removing leaves the persisted active account alone', () async {
      await repository.persistActiveAccount('a');
      await repository.removeAccount('b');
      expect(await repository.persistedActiveUserId(), '@a:s');
    });

    test('an unknown id throws and changes nothing', () async {
      await expectLater(
        repository.removeAccount('x'),
        throwsA(isA<UnknownAccountException>()),
      );
      expect(dataSource.calls, isEmpty);
      expect(registry.clients, hasLength(2));
    });
  });

  group('discardCandidate (D8)', () {
    test('disposes the client, deletes its storage and drops it', () async {
      await repository.createCandidate();
      dataSource.calls.clear();

      await repository.discardCandidate('new-client');

      expect(dataSource.calls, ['delete:new-client']);
      expect(registry['new-client'], isNull);
    });

    test('a failing delete keeps the candidate so it can be retried', () async {
      await repository.createCandidate();
      dataSource.failDelete = true;

      await expectLater(
        repository.discardCandidate('new-client'),
        throwsA(isA<StateError>()),
      );
      expect(registry['new-client'], isNotNull);

      dataSource.failDelete = false;
      await repository.discardCandidate('new-client');

      expect(registry['new-client'], isNull);
    });

    test('a stored account is never discarded', () async {
      repository.adopt([
        FakeAccountClient('a', userID: '@a:s'),
      ], pendingRemovals: const {});
      dataSource.calls.clear();

      await expectLater(
        repository.discardCandidate('a'),
        throwsA(isA<StoredAccountException>()),
      );
      expect(dataSource.calls, isEmpty);
      expect(registry['a'], isNotNull);
    });

    test(
      'a candidate recorded before a restart is made again and deleted',
      () async {
        await repository.markCandidateDiscardPending('old-client');
        expect(await repository.pendingCandidateDiscards(), {'old-client'});
        dataSource.calls.clear();

        await repository.discardCandidate('old-client');

        expect(dataSource.calls, ['create:old-client', 'delete:old-client']);
        expect(registry['old-client'], isNull);

        await repository.clearCandidateDiscardPending('old-client');
        expect(await repository.pendingCandidateDiscards(), isEmpty);
      },
    );

    test('an unknown id throws', () async {
      await expectLater(
        repository.discardCandidate('x'),
        throwsA(isA<UnknownAccountException>()),
      );
    });
  });

  group('persisted active account (D2: stored by userId)', () {
    setUp(() async {
      repository.adopt([
        FakeAccountClient('a', userID: '@a:s'),
        FakeAccountClient('p', logged: false),
      ], pendingRemovals: const {});
    });

    test('nothing is persisted at first', () async {
      expect(await repository.persistedActiveUserId(), isNull);
    });

    test('round trip stores the userId under the unchanged key', () async {
      await repository.persistActiveAccount('a');

      expect(await repository.persistedActiveUserId(), '@a:s');
      expect(
        (await SharedPreferences.getInstance()).getString(
          'persist_active_account_key',
        ),
        '@a:s',
      );
    });

    test(
      'an account without a userId is skipped, as the legacy code does',
      () async {
        await repository.persistActiveAccount('p');
        expect(await repository.persistedActiveUserId(), isNull);
      },
    );

    test('an unknown id throws', () async {
      await expectLater(
        repository.persistActiveAccount('x'),
        throwsA(isA<UnknownAccountException>()),
      );
    });

    test('clear removes the key', () async {
      await repository.persistActiveAccount('a');
      await repository.clearPersistedActiveAccount();
      expect(await repository.persistedActiveUserId(), isNull);
    });
  });

  group('AccountClientRegistry', () {
    test('keeps insertion order and replaceAll swaps the content', () {
      registry
        ..add(FakeAccountClient('b'))
        ..add(FakeAccountClient('a'));
      expect(registry.clients.map((c) => c.clientName), ['b', 'a']);

      registry.replaceAll([FakeAccountClient('c')]);
      expect(registry.clients.map((c) => c.clientName), ['c']);
    });

    test('the exposed list cannot change the registry', () {
      registry.add(FakeAccountClient('a'));
      expect(() => registry.clients.clear(), throwsUnsupportedError);
    });
  });
}

AccountRepositoryImpl _newRepository(
  FakeAccountClientDataSource dataSource,
  AccountClientRegistry registry,
) => AccountRepositoryImpl(
  dataSource: dataSource,
  persistedActiveAccount: PersistedActiveAccountSource(Store()),
  pendingRemovals: PendingRemovalsSource(Store()),
  pendingPushRemovals: PendingRemovalsSource(
    Store(),
    storeKey: PendingRemovalsSource.pushKey,
  ),
  pendingCandidateDiscards: PendingRemovalsSource(
    Store(),
    storeKey: PendingRemovalsSource.candidateKey,
  ),
  registry: registry,
  clientNameBuilder: () => 'new-client',
);
