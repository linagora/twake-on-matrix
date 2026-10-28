import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/data/account/repositories/account_repository_impl.dart';
import 'package:twake_chat/data/account/sources/account_client_registry.dart';
import 'package:twake_chat/data/account/sources/pending_removals_source.dart';
import 'package:twake_chat/data/account/sources/persisted_active_account_source.dart';
import 'package:twake_chat/data/account/logout_removals.dart';
import 'package:twake_chat/data/account/push_removal_plan.dart';
import 'package:twake_chat/utils/famedlysdk_store.dart';

import 'fakes.dart';

void main() {
  late AccountRepositoryImpl repository;
  late LogoutRemovals removals;
  late List<String> events;
  late bool failDeletion;
  late String? sessionToken;
  late bool pushReady;

  Future<void> run() => removals.remove(
    'a',
    PushRemovalPlan(
      id: 'a',
      repository: repository,
      sessionToken: () => sessionToken,
      isPushReady: () => pushReady,
      removePush: () async {
        events.add('delete');
        if (failDeletion) throw StateError('network');
      },
    ).steps,
    (error, stackTrace, what) => events.add('reported'),
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = AccountRepositoryImpl(
      dataSource: FakeAccountClientDataSource(),
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
      registry: AccountClientRegistry(),
    );
    removals = LogoutRemovals();
    events = [];
    failDeletion = false;
    sessionToken = 'token-1';
    pushReady = true;
  });

  tearDown(() => removals.dispose());

  test('a deletion that works leaves nothing recorded', () async {
    await run();

    expect(events, ['delete']);
    expect(await repository.pendingPushRemovals(), isEmpty);
  });

  test(
    'a deletion that fails is reported and recorded across restarts',
    () async {
      failDeletion = true;

      await run();

      expect(events, ['delete', 'reported']);
      expect(await repository.pendingPushRemovals(), {'a'});
      expect(removals.failedIds, {'a'});
    },
  );

  test('the retry deletes again and clears the record when it works', () async {
    failDeletion = true;
    await run();
    failDeletion = false;

    await removals.retryAll();

    expect(await repository.pendingPushRemovals(), isEmpty);
    expect(removals.failedIds, isEmpty);
  });

  test('a record is not written again by a failed retry', () async {
    failDeletion = true;
    await run();

    await removals.retryAll();

    expect(events.where((e) => e == 'delete'), hasLength(2));
    expect(await repository.pendingPushRemovals(), {'a'});
  });

  test('a closed session cannot delete anything and is not retried', () async {
    failDeletion = true;
    await run();
    sessionToken = null;

    await removals.retryAll();

    expect(events.where((e) => e == 'delete'), hasLength(1));
    expect(await repository.pendingPushRemovals(), isEmpty);
    expect(removals.failedIds, isEmpty);
  });

  test(
    'a new session of the same account is not touched by the retry',
    () async {
      failDeletion = true;
      await run();
      failDeletion = false;
      sessionToken = 'token-2';

      await removals.retryAll();

      expect(events.where((e) => e == 'delete'), hasLength(1));
      expect(await repository.pendingPushRemovals(), isEmpty);
      expect(removals.failedIds, isEmpty);
    },
  );

  test(
    'a deletion before the push set-up is a failure that keeps the record',
    () async {
      pushReady = false;

      await run();

      expect(events, ['reported']);
      expect(await repository.pendingPushRemovals(), {'a'});
      expect(removals.failedIds, {'a'});
    },
  );

  test('the retry deletes once the push set-up is ready', () async {
    pushReady = false;
    await run();
    pushReady = true;

    await removals.retryAll();

    expect(events, ['reported', 'delete']);
    expect(await repository.pendingPushRemovals(), isEmpty);
    expect(removals.failedIds, isEmpty);
  });
}
