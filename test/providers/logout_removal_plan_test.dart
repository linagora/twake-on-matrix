import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/data/account/logout_removals.dart';
import 'package:twake_chat/domain/account/entities/account.dart';
import 'package:twake_chat/domain/account/entities/account_id.dart';
import 'package:twake_chat/domain/account/entities/accounts_state.dart';
import 'package:twake_chat/providers/account_repository_provider.dart';
import 'package:twake_chat/providers/account_usecase_providers.dart';
import 'package:twake_chat/providers/accounts_provider.dart';
import 'package:twake_chat/providers/active_account_client_provider.dart';
import 'package:twake_chat/providers/logout_removal_plan.dart';

import '../data/account/fakes.dart';

void main() {
  late ProviderContainer container;
  late FakeAccountClientDataSource dataSource;
  late LogoutRemovals removals;
  late List<String> events;
  late bool failCancel;
  late bool failActivate;
  late bool failAnnounce;

  AccountsState state() => container.read(accountsProvider);
  Accounts notifier() => container.read(accountsProvider.notifier);

  FakeAccountClient user(String id) => FakeAccountClient(id, userID: '@$id:s');

  void boot(List<FakeAccountClient> clients, {Set<String> pending = const {}}) {
    dataSource = FakeAccountClientDataSource();
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        accountClientDataSourceProvider.overrideWithValue(dataSource),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(adoptBootAccountsUseCaseProvider(clients))
        .execute(pendingRemovals: pending);
  }

  Future<bool> logout(String id, {bool announce = true}) => removals.remove(
    id,
    LogoutRemovalPlan(
      id: id,
      accounts: notifier(),
      isActive: () =>
          container.read(activeAccountClientProvider)?.clientName == id,
      cancelSubscriptions: () async {
        events.add('cancel:$id');
        if (failCancel) throw StateError('cancel');
      },
      activateReplacement: () async {
        events.add('activate:${state().runtimeType}');
        if (failActivate) throw StateError('effects');
      },
      announce: announce
          ? () async {
              events.add('announce:$id');
              if (failAnnounce) throw StateError('contacts');
            }
          : null,
    ).steps,
    (error, stackTrace, what) {},
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    removals = LogoutRemovals();
    events = [];
    failCancel = false;
    failActivate = false;
    failAnnounce = false;
  });

  tearDown(() => removals.dispose());

  test(
    'the active account that is removed hands over and is announced',
    () async {
      boot([user('a'), user('b')]);

      expect(await logout('a'), isTrue);

      expect(events, ['cancel:a', 'announce:a', 'activate:Active']);
      expect((state() as Active).activeId, 'b');
    },
  );

  test(
    'a non-active account is removed without touching the active one',
    () async {
      boot([user('a'), user('b')]);

      await logout('b');

      expect(events, ['cancel:b', 'announce:b']);
      expect((state() as Active).activeId, 'a');
    },
  );

  test(
    'when the subscriptions cannot be cancelled the active account is held, and the replacement still gets its effects',
    () async {
      boot([user('a'), user('b')]);
      failCancel = true;

      expect(await logout('a'), isFalse);

      expect((state() as Active).activeId, 'b');
      expect(state().accounts.first.status, AccountStatus.unavailable);
      expect(events, ['cancel:a', 'announce:a', 'activate:Active']);
    },
  );

  test(
    'the replacement effects are not applied again when the removal later works',
    () async {
      boot([user('a'), user('b')]);
      failCancel = true;
      await logout('a');
      failCancel = false;
      events.clear();

      await removals.retryAll();

      expect(events, ['cancel:a']);
      expect(state().accounts.map((x) => x.id), ['b']);
    },
  );

  test(
    'effects that fail after the removal are retried without removing again',
    () async {
      boot([user('a'), user('b')]);
      failActivate = true;

      expect(await logout('a'), isTrue);
      expect(removals.failedIds, {'a'});
      failActivate = false;
      await removals.retryAll();

      expect(removals.failedIds, isEmpty);
      expect(dataSource.calls.where((c) => c == 'delete:a'), hasLength(1));
      expect(events.where((e) => e == 'announce:a'), hasLength(1));
      expect(events.where((e) => e.startsWith('activate')), hasLength(2));
    },
  );

  test(
    'a removal that fails with no logged-in survivor holds the account and logs nobody in',
    () async {
      boot([user('a'), user('b')]);
      await notifier().holdRemoval(const AccountId('b'));
      dataSource.failDelete = true;

      expect(await logout('a'), isFalse);

      expect(state(), isA<NoAccount>());
      expect(state().accounts.map((x) => x.id), ['a', 'b']);
      expect(events, contains('activate:NoAccount'));
      expect(removals.failedIds, {'a'});
    },
  );

  test(
    'accounts left from the last run are removed even with nobody logged in',
    () async {
      boot([user('a'), user('b')], pending: {'a', 'b'});
      expect(state(), isA<NoAccount>());

      await logout('a', announce: false);
      await logout('b', announce: false);

      expect(state(), const NoAccount());
      expect(events, ['cancel:a', 'cancel:b']);
    },
  );

  test(
    'an announcement that fails is retried, and not again once it worked',
    () async {
      boot([user('a'), user('b')]);
      failAnnounce = true;

      expect(await logout('b'), isTrue);
      expect(removals.failedIds, {'b'});
      failAnnounce = false;
      await removals.retryAll();
      await removals.retryAll();

      expect(removals.failedIds, isEmpty);
      expect(events.where((e) => e == 'announce:b'), hasLength(2));
      expect(dataSource.calls.where((c) => c == 'delete:b'), hasLength(1));
    },
  );
}
