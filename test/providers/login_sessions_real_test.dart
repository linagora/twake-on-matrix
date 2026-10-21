import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/data/account/datasources_impl/fault_injecting_account_data_source.dart';
import 'package:twake_chat/data/account/sources/pending_removals_source.dart';
import 'package:twake_chat/domain/account/entities/account.dart';
import 'package:twake_chat/domain/account/entities/account_id.dart';
import 'package:twake_chat/domain/account/entities/accounts_state.dart';
import 'package:twake_chat/presentation/model/client_login_state_event.dart';
import 'package:twake_chat/providers/account_interactor_providers.dart';
import 'package:twake_chat/providers/account_repository_provider.dart';
import 'package:twake_chat/providers/account_switch_coordinator.dart';
import 'package:twake_chat/providers/accounts_provider.dart';
import 'package:twake_chat/providers/login_candidate_provider.dart';
import 'package:twake_chat/providers/login_host.dart';
import 'package:twake_chat/providers/login_session.dart';
import 'package:twake_chat/providers/login_sessions.dart';
import 'package:twake_chat/providers/logout_removals.dart';
import 'package:twake_chat/providers/rollback_removals.dart';
import 'package:twake_chat/utils/famedlysdk_store.dart';

import '../data/account/fakes.dart';
import 'account_switch_coordinator_test.dart'
    show FakeSwitchEffects, LoginableClient;

/// A host over the real repository, notifier and switch coordinator; only what
/// needs a widget tree is recorded.
class _RealHost implements LoginHost {
  _RealHost(this.container, this.coordinator) {
    rollback = RollbackRemovals(
      repository: container.read(accountRepositoryProvider),
      accounts: container.read(accountsProvider.notifier),
      storedRemovals: stored,
      candidateRemovals: candidates,
      isActive: (id) => activeClientName == id,
      cancelSubscriptions: (id) async => calls.add('removalCancelSubs:$id'),
      report: (error, stackTrace, what) => calls.add('report:$what'),
    );
  }

  final stored = LogoutRemovals();
  final candidates = LogoutRemovals();
  late final RollbackRemovals rollback;

  final ProviderContainer container;
  final AccountSwitchCoordinator coordinator;
  final calls = <String>[];
  final events = <ClientLoginStateEvent>[];
  final failing = <String>{};
  final streams = <String, StreamController<LoginState>>{};

  Accounts get _accounts => container.read(accountsProvider.notifier);
  AccountsState get _state => container.read(accountsProvider);

  Future<void> _step(String name) async {
    calls.add(name);
    if (failing.contains(name)) throw StateError('$name failed');
  }

  Client? _client(String id) =>
      container.read(accountClientRegistryProvider)[id];

  @override
  bool isStored(AccountId id) => container
      .read(accountRepositoryProvider)
      .registeredAccounts()
      .any((a) => a.id == id.value);

  @override
  bool isLoggedIn(AccountId id) => _client(id.value)?.isLogged() ?? false;

  @override
  Future<void> addAccount(AccountId id) async {
    calls.add('addAccount:${id.value}');
    await _accounts.addAccount(id);
  }

  @override
  Future<void> removeAccount(AccountId id) async {
    calls.add('removeAccount:${id.value}');
    await rollback.removeStored(id.value, activateReplacement: () async {});
  }

  @override
  void logoutLast() {
    calls.add('logoutLast');
    _accounts.logoutLast();
  }

  @override
  String? get activeClientName {
    final state = _state;
    return state is Active ? state.activeId : null;
  }

  @override
  Client get activeClient => _client(activeClientName!)!;

  @override
  Client? clientByName(AccountId id) => _client(id.value);

  @override
  Future<bool> switchTo(Client client) async {
    calls.add('switchTo:${client.clientName}');
    await _accounts.switchTo(AccountId(client.clientName));
    return !failing.contains('switchAfter:${client.clientName}');
  }

  @override
  Future<void> applyEffects(Client client) async {
    calls.add('apply:${client.clientName}');
    await coordinator.apply(client);
  }

  @override
  Future<void> clearEffects() async => calls.add('clearEffects');

  @override
  Future<void> activateCurrent() async {
    calls.add('activateCurrent');
    if (failing.contains('activateCurrent')) {
      throw StateError('activateCurrent failed');
    }
    await coordinator.activateCurrent();
  }

  @override
  Client? get reusableClient => container.read(loginCandidateProvider);

  @override
  Future<Client> createCandidate() async {
    final account = await container
        .read(accountRepositoryProvider)
        .createCandidate();
    return _client(account.id)!;
  }

  @override
  Future<void> discardCandidate(AccountId id) async {
    calls.add('discardCandidate:${id.value}');
    await rollback.discardCandidate(id.value);
  }

  @override
  String? get pendingCandidateId =>
      container.read(pendingLoginCandidateProvider);

  @override
  void setPendingCandidate(AccountId? id) =>
      container.read(pendingLoginCandidateProvider.notifier).set(id?.value);

  @override
  Future<void> signOut(AccountId id, {required bool quiet}) =>
      _step('signOut:${id.value}');

  @override
  void forgetQuiet(AccountId id) {}

  @override
  StreamSubscription<LoginState> listenLoginState(
    Client client,
    void Function(LoginState state) onState,
  ) => streams
      .putIfAbsent(
        client.clientName,
        () => StreamController<LoginState>.broadcast(),
      )
      .stream
      .listen(onState);

  @override
  Future<void> removePush(AccountId id) => _step('removePush:${id.value}');

  @override
  Future<void> cancelSubscriptions(AccountId id) =>
      _step('cancelSubs:${id.value}');

  @override
  Future<void> registerSubscriptions(AccountId id) =>
      _step('registerSubs:${id.value}');

  @override
  Future<void> setUpToM(Client client) => _step('tom:${client.clientName}');

  @override
  Future<void> setUpFederation(Client client) =>
      _step('federation:${client.clientName}');

  @override
  Future<void> syncRecoveryKey(Client client) async {}

  @override
  Future<void> setUpAdditionalPush(Client client) =>
      _step('push:${client.clientName}');

  @override
  Future<void> cancelContactSync() async {}

  @override
  void reSyncContacts() {}

  @override
  void markFirstSyncDone() {}

  @override
  void emit(ClientLoginStateEvent event) {
    calls.add('emit:${event.multipleAccountLoginType.name}');
    events.add(event);
  }

  @override
  Future<void> retryPendingRemovals() async {
    await stored.retryAll();
    await candidates.retryAll();
  }

  @override
  void report(Object error, StackTrace stackTrace, String what) =>
      calls.add('report:$what');

  /// The server accepts the login of [id]: it is logged in, then `loggedIn`.
  Future<void> logIn(String id) async {
    (_client(id)! as LoginableClient).loggedIn = true;
    streams[id]!.add(LoginState.loggedIn);
    await pumpEventQueue();
  }
}

void main() {
  late FakeAccountClientDataSource dataSource;
  late ProviderContainer container;
  late FakeSwitchEffects effects;
  late AccountSwitchCoordinator coordinator;
  late _RealHost host;
  late LoginSessions sessions;
  late FakeAccountClient a;

  void boot({
    List<FakeAccountClient> accounts = const [],
    Set<String> pending = const {},
    bool faults = false,
  }) {
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        accountClientDataSourceProvider.overrideWithValue(
          faults
              ? FaultInjectingAccountDataSource(
                  dataSource,
                  failAddClientNameOnce: true,
                )
              : dataSource,
        ),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(adoptBootAccountsInteractorProvider(accounts))
        .execute(pendingRemovals: pending);
    effects = FakeSwitchEffects();
    coordinator = AccountSwitchCoordinator(
      effects: effects,
      accounts: container.read(accountsProvider.notifier),
      clientOf: (id) => container.read(accountClientRegistryProvider)[id],
      currentState: () => container.read(accountsProvider),
    )..start();
    container.listen(accountsProvider, coordinator.onAccountsChanged);
    host = _RealHost(container, coordinator);
    addTearDown(host.stored.dispose);
    addTearDown(host.candidates.dispose);
    sessions = LoginSessions(host);
  }

  PendingRemovalsSource candidateRecords() => PendingRemovalsSource(
    Store(),
    storeKey: PendingRemovalsSource.candidateKey,
  );

  Iterable<MultipleAccountLoginType> events() =>
      host.events.map((e) => e.multipleAccountLoginType);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dataSource = FakeAccountClientDataSource()
      ..clientFactory = ((name) => LoginableClient(name, userID: '@$name:s'));
    a = FakeAccountClient('a', userID: '@a:s');
  });

  group('add another account', () {
    test(
      'stores, switches, reports and clears the pending candidate',
      () async {
        boot(accounts: [a]);
        final client = await sessions.loginClient();

        await host.logIn(client.clientName);

        expect(
          sessions.sessionOf(client.clientName)!.state,
          LoginSessionState.active,
        );
        expect(
          (container.read(accountsProvider) as Active).activeId,
          client.clientName,
        );
        expect(events(), [MultipleAccountLoginType.otherAccountLoggedIn]);
        expect(host.pendingCandidateId, isNull);
      },
    );

    test(
      'a failure after the switch removes the candidate, its storage first, and the next account is active again',
      () async {
        boot(accounts: [a]);
        final client = await sessions.loginClient();
        final id = client.clientName;
        host.failing.add('switchAfter:$id');

        await host.logIn(id);

        expect(
          host.calls,
          containsAllInOrder([
            'switchTo:$id',
            'cancelSubs:$id',
            'signOut:$id',
            'removeAccount:$id',
            'apply:a',
            'emit:loginFailed',
          ]),
        );
        expect(
          dataSource.calls.indexOf('delete:$id'),
          lessThan(dataSource.calls.indexOf('remove:$id')),
        );
        expect(container.read(accountClientRegistryProvider)[id], isNull);
        expect(host.pendingCandidateId, isNull);
        final state = container.read(accountsProvider) as Active;
        expect(state.activeId, 'a');
        expect(state.accounts.map((x) => x.id), ['a']);
        expect(effects.log.where((e) => e.startsWith('tom:')), [
          'tom:$id',
          'tom:a',
        ]);
        expect(effects.store['tom'], 'a');
      },
    );

    test(
      'a storage that cannot be deleted leaves the account listed, says so, and a retry finishes it',
      () async {
        boot(accounts: [a]);
        final client = await sessions.loginClient();
        final id = client.clientName;
        host.failing.add('switchAfter:$id');
        dataSource.failDelete = true;

        await host.logIn(id);

        expect(sessions.sessionOf(id)!.state, LoginSessionState.cleanupFailed);
        expect(events(), [MultipleAccountLoginType.cleanupFailed]);
        expect(container.read(accountClientRegistryProvider)[id], isNotNull);
        final held = container
            .read(accountsProvider)
            .accounts
            .firstWhere((x) => x.id == id);
        expect(held.status, AccountStatus.unavailable);
        expect(await PendingRemovalsSource(Store()).read(), {id});
        expect(host.stored.failedIds, {id});
        expect(
          container
              .read(accountRepositoryProvider)
              .registeredAccounts()
              .map((x) => x.id),
          contains(id),
        );

        dataSource.failDelete = false;
        await sessions.retryFailedCleanups();

        expect(sessions.sessionOf(id)!.state, LoginSessionState.disposed);
        expect(container.read(accountClientRegistryProvider)[id], isNull);
        expect(events(), [MultipleAccountLoginType.cleanupFailed]);
        expect(await PendingRemovalsSource(Store()).read(), isEmpty);
      },
    );

    test(
      'a candidate whose storage cannot be deleted is recorded across restarts and deleted after one',
      () async {
        boot(accounts: [a]);
        final client = await sessions.loginClient();
        final id = client.clientName;
        dataSource
          ..failAddName = true
          ..failDelete = true;

        await host.logIn(id);

        expect(sessions.sessionOf(id)!.state, LoginSessionState.cleanupFailed);
        expect(host.candidates.failedIds, {id});
        expect(await candidateRecords().read(), {id});

        // A restart: a new container over the same store, the client is gone.
        dataSource
          ..failAddName = false
          ..failDelete = false
          ..calls.clear();
        boot(accounts: [a]);
        await host.rollback.retryRecordedDiscards();

        expect(dataSource.calls, ['create:$id', 'delete:$id']);
        expect(container.read(accountClientRegistryProvider)[id], isNull);
        expect(await candidateRecords().read(), isEmpty);
      },
    );

    test(
      'a candidate that is thrown away mid-creation leaves no client behind',
      () async {
        boot(accounts: [a]);
        final creating = sessions.loginClient();
        final discarding = sessions.discardPending();

        await creating;
        await discarding;

        expect(
          container
              .read(accountClientRegistryProvider)
              .clients
              .map((c) => c.clientName),
          ['a'],
        );
        expect(host.pendingCandidateId, isNull);
      },
    );
  });

  group('nobody is logged in and removals are pending', () {
    late FakeAccountClient waiting;

    setUp(() {
      waiting = FakeAccountClient('w', userID: '@w:s', logged: false);
    });

    test(
      'the login gets a new client, never the one waiting for its removal',
      () async {
        boot(accounts: [waiting], pending: {'w'});

        final client = await sessions.loginClient();
        expect(client.clientName, isNot('w'));
        await host.logIn(client.clientName);

        expect(events(), [MultipleAccountLoginType.otherAccountLoggedIn]);
        final state = container.read(accountsProvider) as Active;
        expect(state.activeId, client.clientName);
        expect(state.accounts.map((x) => x.id), ['w', client.clientName]);
        expect(state.accounts.first.status, AccountStatus.unavailable);
      },
    );

    test('a first login that is rolled back keeps the waiting account listed '
        'and the same client can log in again', () async {
      boot(accounts: [waiting], pending: {'w'});
      final placeholder = await container
          .read(accountRepositoryProvider)
          .createCandidate();
      final client =
          container.read(accountClientRegistryProvider)[placeholder.id]!
                as LoginableClient
            ..loggedIn = true;
      host.failing.add('activateCurrent');

      await sessions.firstLoggedIn(client, LoginState.loggedIn);

      expect(events(), [MultipleAccountLoginType.loginFailed]);
      final state = container.read(accountsProvider) as NoAccount;
      expect(state.candidateId, client.clientName);
      expect(state.accounts.map((x) => x.id), ['w']);

      host.failing.clear();
      await sessions.firstLoggedIn(client, LoginState.loggedIn);

      expect(events().last, MultipleAccountLoginType.firstLoggedIn);
      expect(container.read(accountsProvider), isA<Active>());
    });
  });

  group('with the fault that makes storing the name fail once', () {
    test(
      'add-account: the first try fails cleanly, the second one works',
      () async {
        boot(accounts: [a], faults: true);
        final first = await sessions.loginClient();

        await host.logIn(first.clientName);

        expect(events(), [MultipleAccountLoginType.loginFailed]);
        expect(
          container.read(accountClientRegistryProvider)[first.clientName],
          isNull,
        );
        expect(dataSource.calls, contains('delete:${first.clientName}'));

        final second = await sessions.loginClient();
        await host.logIn(second.clientName);

        expect(events(), [
          MultipleAccountLoginType.loginFailed,
          MultipleAccountLoginType.otherAccountLoggedIn,
        ]);
        expect(container.read(accountsProvider).accounts.map((x) => x.id), [
          'a',
          second.clientName,
        ]);
      },
    );

    test(
      'first login: a failed set-up is rolled back and the same client logs in again',
      () async {
        boot(accounts: const []);
        final placeholder = await container
            .read(accountRepositoryProvider)
            .createCandidate();
        final client =
            container.read(accountClientRegistryProvider)[placeholder.id]!
                  as LoginableClient
              ..loggedIn = true;
        host.failing.add('activateCurrent');

        await sessions.firstLoggedIn(client, LoginState.loggedIn);

        expect(events(), [MultipleAccountLoginType.loginFailed]);
        expect(container.read(accountsProvider), isA<LastLoggedOut>());
        expect(
          container.read(accountClientRegistryProvider)[client.clientName],
          same(client),
        );

        host.failing.clear();
        await sessions.firstLoggedIn(client, LoginState.loggedIn);

        expect(events().last, MultipleAccountLoginType.firstLoggedIn);
        expect(container.read(accountsProvider), isA<Active>());
      },
    );
  });
}
