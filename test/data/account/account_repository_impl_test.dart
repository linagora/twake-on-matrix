import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/data/account/repositories/account_repository_impl.dart';
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
    repository = _newRepository(dataSource, registry);
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

    test('a marked account is listed as unavailable', () async {
      repository.adopt([
        FakeAccountClient('a', userID: '@a:s'),
      ], pendingRemovals: const {});

      await repository.markRemovalPending('a');

      expect(repository.accountOf('a').status, AccountStatus.unavailable);
    });

    test('an unknown id or a candidate cannot be marked', () async {
      await repository.createCandidate();

      await expectLater(
        repository.markRemovalPending('x'),
        throwsA(isA<UnknownAccountException>()),
      );
      await expectLater(
        repository.markRemovalPending('new-client'),
        throwsA(isA<NotStoredAccountException>()),
      );
      expect(await repository.pendingRemovalIds(), isEmpty);
    });

    test('the ids of clients that are gone are dropped at boot', () async {
      repository.adopt(
        [FakeAccountClient('a', userID: '@a:s')],
        pendingRemovals: const {'a', 'gone'},
      );

      await repository.markRemovalPending('a');

      expect(await repository.pendingRemovalIds(), {'a'});
    });

    test(
      'a stale id persisted by a past session is not written back',
      () async {
        await _adoptWithStaleId(repository);

        await repository.markRemovalPending('a');

        expect(await PendingRemovalsSource(Store()).read(), {'a'});
        expect(await repository.pendingRemovalIds(), {'a'});
      },
    );

    test('removing an account drops the stale ids from the store', () async {
      await _adoptWithStaleId(repository);

      await repository.removeAccount('a');

      expect(await PendingRemovalsSource(Store()).read(), isEmpty);
    });

    test('after adopt a stale id is not reported as pending', () async {
      await PendingRemovalsSource(Store()).write({'gone', 'a'});
      repository.adopt(
        [FakeAccountClient('a', userID: '@a:s')],
        pendingRemovals: const {'gone', 'a'},
      );

      expect(await repository.pendingRemovalIds(), {'a'});
    });

    test('before adopt the persisted ids are returned for the boot', () async {
      await PendingRemovalsSource(Store()).write({'a'});

      expect(await repository.pendingRemovalIds(), {'a'});
    });

    test('a record that cannot be cleared does not fail the removal', () async {
      final failing =
          AccountRepositoryImpl(
            dataSource: dataSource,
            persistedActiveAccount: PersistedActiveAccountSource(Store()),
            pendingRemovals: _FailingWrite(),
            pendingPushRemovals: PendingRemovalsSource(Store()),
            pendingCandidateDiscards: PendingRemovalsSource(Store()),
            registry: registry,
          )..adopt(
            [
              FakeAccountClient('a', userID: '@a:s'),
              FakeAccountClient('b', userID: '@b:s'),
            ],
            pendingRemovals: const {'a'},
          );

      await failing.removeAccount('a');

      expect(registry['a'], isNull);
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
      expect(registry['a'], isNotNull);
      expect(registry['b'], isNotNull);
    });
  });

  group('discardCandidate', () {
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

  group('persisted active account', () {
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
    test('replaceAll swaps the content', () {
      registry
        ..add(FakeAccountClient('b'))
        ..add(FakeAccountClient('a'));

      registry.replaceAll([FakeAccountClient('c')]);

      expect(registry['a'], isNull);
      expect(registry['b'], isNull);
      expect(registry['c'], isNotNull);
    });
  });

  group('pending pushers and candidates are owned by the store', () {
    for (final kind in _Kind.values) {
      group(kind.name, () {
        test(
          'a read that finishes late does not bring a cleared id back',
          () async {
            final source = _GatedSource();
            final repo = _repositoryWith(dataSource, registry, kind, source);
            await kind.mark(repo, 'x');

            final gate = source.holdNextRead();
            final staleRead = kind.read(repo);
            await kind.clear(repo, 'x');
            gate.complete();

            expect(await staleRead, {'x'});
            await kind.mark(repo, 'y');
            expect(await kind.read(repo), {'y'});
            expect(await source.read(), {'y'});
          },
        );

        test('two marks in parallel keep both ids', () async {
          final source = _GatedSource();
          final repo = _repositoryWith(dataSource, registry, kind, source);

          await Future.wait([kind.mark(repo, 'a'), kind.mark(repo, 'b')]);

          expect(await kind.read(repo), {'a', 'b'});
        });

        test('a new repository on the same store sees every write', () async {
          final source = _GatedSource();
          final repo = _repositoryWith(dataSource, registry, kind, source);
          await kind.mark(repo, 'a');
          await kind.mark(repo, 'b');
          await kind.clear(repo, 'a');

          final restarted = _repositoryWith(dataSource, registry, kind, source);

          expect(await kind.read(restarted), {'b'});
        });

        test('marking or clearing twice is the same as once', () async {
          final source = _GatedSource();
          final repo = _repositoryWith(dataSource, registry, kind, source);

          await kind.mark(repo, 'a');
          await kind.mark(repo, 'a');
          expect(await source.read(), {'a'});

          await kind.clear(repo, 'a');
          await kind.clear(repo, 'a');
          expect(await source.read(), isEmpty);
        });
      });
    }
  });
}

enum _Kind {
  push,
  candidate;

  Future<Set<String>> read(AccountRepositoryImpl r) => switch (this) {
    push => r.pendingPushRemovals(),
    candidate => r.pendingCandidateDiscards(),
  };

  Future<void> mark(AccountRepositoryImpl r, String id) => switch (this) {
    push => r.markPushRemovalPending(id),
    candidate => r.markCandidateDiscardPending(id),
  };

  Future<void> clear(AccountRepositoryImpl r, String id) => switch (this) {
    push => r.clearPushRemovalPending(id),
    candidate => r.clearCandidateDiscardPending(id),
  };
}

AccountRepositoryImpl _repositoryWith(
  FakeAccountClientDataSource dataSource,
  AccountClientRegistry registry,
  _Kind kind,
  PendingRemovalsSource source,
) => AccountRepositoryImpl(
  dataSource: dataSource,
  persistedActiveAccount: PersistedActiveAccountSource(Store()),
  pendingRemovals: PendingRemovalsSource(Store()),
  pendingPushRemovals: kind == _Kind.push ? source : _GatedSource(),
  pendingCandidateDiscards: kind == _Kind.candidate ? source : _GatedSource(),
  registry: registry,
);

/// In-memory store whose next read can be held until the test releases it,
/// returning what was stored when the read started.
class _GatedSource extends PendingRemovalsSource {
  _GatedSource() : super(Store());

  Set<String> _ids = {};
  Completer<void>? _gate;

  Completer<void> holdNextRead() => _gate = Completer<void>();

  @override
  Future<Set<String>> read() async {
    final snapshot = {..._ids};
    final gate = _gate;
    _gate = null;
    if (gate != null) await gate.future;
    return snapshot;
  }

  @override
  Future<void> write(Set<String> ids) async => _ids = {...ids};
}

/// Adopts the accounts 'a' and 'b' with a removal of 'gone' persisted by a
/// past session.
Future<void> _adoptWithStaleId(AccountRepositoryImpl repository) async {
  await PendingRemovalsSource(Store()).write({'gone'});
  repository.adopt(
    [
      FakeAccountClient('a', userID: '@a:s'),
      FakeAccountClient('b', userID: '@b:s'),
    ],
    pendingRemovals: const {'gone'},
  );
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

class _FailingWrite extends PendingRemovalsSource {
  _FailingWrite() : super(Store());

  @override
  Future<void> write(Set<String> ids) => Future.error(StateError('read-only'));
}
