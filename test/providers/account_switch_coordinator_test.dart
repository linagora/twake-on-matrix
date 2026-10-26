import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/domain/account/entities/account_boot_snapshot.dart';
import 'package:twake_chat/domain/account/entities/account_id.dart';
import 'package:twake_chat/domain/account/entities/accounts_state.dart';
import 'package:twake_chat/domain/account/exceptions/account_exception.dart';
import 'package:twake_chat/providers/account_boot_snapshot_provider.dart';
import 'package:twake_chat/providers/account_repository_provider.dart';
import 'package:twake_chat/providers/account_switch_coordinator.dart';
import 'package:twake_chat/providers/accounts_provider.dart';
import 'package:twake_chat/providers/boot_clients_provider.dart';

import '../data/account/fakes.dart';

/// A client that can log in after it was adopted, as the placeholder of a
/// first login does.
class LoginableClient extends FakeAccountClient {
  LoginableClient(super.clientName, {super.userID}) : super(logged: false);

  bool loggedIn = false;

  @override
  bool isLogged() => loggedIn;
}

/// Records the steps in the order they run. A step can be held on a gate or
/// made to throw; both are keyed by `name` or by `name:account`.
///
/// What a real body does after its awaits is simulated: it writes into
/// [store] only while its token is current, and [checks] records the answer.
class FakeSwitchEffects implements AccountSwitchEffects {
  final log = <String>[];
  final checks = <String>[];
  final store = <String, String>{};
  final gates = <String, Completer<void>>{};
  final failing = <String>{};

  Future<void> _step(String name, Client client, SwitchToken token) async {
    final id = client.clientName;
    log.add('$name:$id');
    if (failing.contains(name) || failing.contains('$name:$id')) {
      throw StateError('$name failed');
    }
    await (gates[name] ?? gates['$name:$id'])?.future;
    checks.add('$name:$id:${token.isCurrent}');
    if (token.isCurrent) store[name] = id;
  }

  @override
  void createVoipPlugin() => log.add('voip');

  @override
  Future<void> setUpToM(Client client, SwitchToken token) =>
      _step('tom', client, token);

  @override
  Future<void> persistActiveAccount(Client client, SwitchToken token) =>
      _step('persist', client, token);

  @override
  Future<void> loadUserInfo(Client client, SwitchToken token) =>
      _step('userInfo', client, token);

  @override
  Future<void> loadHomeserverInfo(Client client, SwitchToken token) =>
      _step('homeserver', client, token);

  @override
  void refreshContacts(Client client) {
    log.add('contacts:${client.clientName}');
    if (failing.contains('contacts') ||
        failing.contains('contacts:${client.clientName}')) {
      throw StateError('contacts failed');
    }
  }

  @override
  void createSupportChat(Client client) =>
      log.add('support:${client.clientName}');

  @override
  void listenPresence(Client client) =>
      log.add('presence:${client.clientName}');

  @override
  void configureSentryUser(Client client) =>
      log.add('sentry:${client.clientName}');
}

void main() {
  late ProviderContainer container;
  late FakeSwitchEffects effects;
  late AccountSwitchCoordinator coordinator;
  late ProviderSubscription<AccountsState> subscription;
  late FakeAccountClient a;
  late FakeAccountClient b;
  late FakeAccountClient c;

  const fullRun = [
    'voip',
    'tom',
    'persist',
    'userInfo',
    'homeserver',
    'contacts',
    'support',
    'presence',
    'sentry',
  ];

  List<String> fullRunFor(String id) => [
    for (final step in fullRun)
      if (step == 'voip') step else '$step:$id',
  ];

  /// Wires the coordinator as `MatrixState.initState` does.
  void boot({Client? Function(String id)? clientOf, List<Client>? clients}) {
    final adopted = clients ?? [a, b, c];
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        accountClientDataSourceProvider.overrideWithValue(
          FakeAccountClientDataSource(),
        ),
        bootClientsProvider.overrideWithValue(adopted),
        bootAccountSnapshotProvider.overrideWithValue(
          const AccountBootSnapshot(),
        ),
      ],
    );
    container.read(accountsProvider);
    final registry = {for (final client in adopted) client.clientName: client};
    coordinator = AccountSwitchCoordinator(
      effects: effects,
      accounts: container.read(accountsProvider.notifier),
      clientOf: clientOf ?? (id) => registry[id],
      currentState: () => container.read(accountsProvider),
    )..start();
    subscription = container.listen(
      accountsProvider,
      coordinator.onAccountsChanged,
    );
  }

  AccountsState state() => container.read(accountsProvider);
  Future<void> switchTo(String id) =>
      container.read(accountsProvider.notifier).switchTo(AccountId(id));
  Future<void> pump() => Future<void>.delayed(Duration.zero);

  /// Lets the background work that nobody awaits (a restore) run to its end.
  Future<void> settle() => pumpEventQueue();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    effects = FakeSwitchEffects();
    a = FakeAccountClient('a', userID: '@a:s');
    b = FakeAccountClient('b', userID: '@b:s');
    c = FakeAccountClient('c', userID: '@c:s');
  });

  group('order', () {
    test('runs the effects in the order they always ran, then ends', () async {
      boot();
      await switchTo('b');
      expect(effects.log, fullRunFor('b'));
      expect((state() as Active).activeId, 'b');
      expect(coordinator.hasApplied, isTrue);
      expect(coordinator.target, isNull);
    });

    test('switchTo is not done until the last effect ended', () async {
      effects.gates['homeserver'] = Completer<void>();
      boot();
      var done = false;
      final switching = switchTo('b').then((_) => done = true);
      await pump();
      expect(state(), isA<Switching>());
      expect((state() as Switching).from, 'a');
      expect(coordinator.target, same(b));
      expect(done, isFalse);
      effects.gates['homeserver']!.complete();
      await switching;
      expect(state(), isA<Active>());
      expect(effects.log, fullRunFor('b'));
    });
  });

  group('errors', () {
    test('a throwing step ends the switch, skips the next steps and '
        'rethrows; earlier steps are not undone', () async {
      effects.failing.add('homeserver:b');
      boot();
      await expectLater(switchTo('b'), throwsStateError);
      const failedRun = [
        'voip',
        'tom:b',
        'persist:b',
        'userInfo:b',
        'homeserver:b',
      ];
      expect(effects.log.take(failedRun.length), failedRun);
      expect((state() as Active).activeId, 'a');
      expect(coordinator.isAppliedTo(b), isFalse);
      await settle();
      expect(effects.log, failedRun);
      expect(coordinator.target, isNull);
    });

    test('the origin that was never applied is not restored', () async {
      effects.failing.add('homeserver:b');
      boot();
      expect(coordinator.hasApplied, isFalse);
      await expectLater(switchTo('b'), throwsStateError);
      await settle();

      expect(effects.log.where((e) => e.endsWith(':a')), isEmpty);
      expect(coordinator.hasApplied, isFalse);
      expect((state() as Active).activeId, 'a');
    });

    test('an origin applied before a failed switch is restored even when '
        'the switch was retried first', () async {
      boot();
      await coordinator.apply(a);
      effects.log.clear();
      effects.failing.add('homeserver:c');
      effects.gates['tom:b'] = Completer<void>();
      final first = expectLater(
        switchTo('b'),
        throwsA(isA<SwitchSupersededException>()),
      );
      await pump();
      final second = expectLater(switchTo('c'), throwsStateError);
      await pump();
      effects.gates['tom:b']!.complete();
      await first;
      await second;
      await settle();

      expect(effects.log.where((e) => e == 'sentry:a'), hasLength(1));
      expect(coordinator.isAppliedTo(a), isTrue);
    });

    test(
      'a throwing sync step after the awaits also fails the switch',
      () async {
        effects.failing.add('contacts:b');
        boot();
        await expectLater(switchTo('b'), throwsStateError);
        expect(effects.log, contains('contacts:b'));
        expect((state() as Active).activeId, 'a');
      },
    );

    test('an account without a client fails the switch', () async {
      boot(clientOf: (id) => id == 'b' ? null : a);
      await expectLater(switchTo('b'), throwsA(isA<UnknownAccountException>()));
      expect(effects.log, isEmpty);
      expect((state() as Active).activeId, 'a');
    });
  });

  group('stale switch', () {
    test('an apply from elsewhere makes the running switch fail, not '
        'complete', () async {
      effects.gates['tom:b'] = Completer<void>();
      boot();
      final result = expectLater(
        switchTo('b'),
        throwsA(isA<SwitchSupersededException>()),
      );
      await pump();

      await coordinator.apply(c);
      effects.gates['tom:b']!.complete();
      await result;
      await settle();

      expect((state() as Active).activeId, 'a');
      expect(effects.store['tom'], 'c');
    });

    test(
      'a switch replaced by a newer one is not logged as a failure',
      () async {
        effects.gates['userInfo'] = Completer<void>();
        boot();
        Logs().outputEvents.clear();
        final first = switchTo('b');
        final firstResult = expectLater(
          first,
          throwsA(isA<SwitchSupersededException>()),
        );
        await pump();

        final second = switchTo('c');
        await pump();
        effects.gates['userInfo']!.complete();
        await second;
        await firstResult;

        expect(Logs().outputEvents.where((e) => e.level == Level.wtf), isEmpty);
      },
    );

    test('a newer switch wins; the older effects stop at their next '
        'checkpoint', () async {
      effects.gates['userInfo'] = Completer<void>();
      boot();
      final first = switchTo('b');
      final firstResult = expectLater(
        first,
        throwsA(isA<SwitchSupersededException>()),
      );
      await pump();
      expect(effects.log.last, 'userInfo:b');

      final second = switchTo('c');
      await pump();
      effects.gates['userInfo']!.complete();
      await second;
      await firstResult;
      await pump();

      expect((state() as Active).activeId, 'c');
      expect(effects.log.where((e) => e.endsWith(':a')), isEmpty);
      expect(effects.store.values.toSet(), {'c'});
      expect(effects.log.where((e) => e == 'homeserver:b'), isEmpty);
      expect(effects.log.where((e) => e.endsWith(':b')), [
        'tom:b',
        'persist:b',
        'userInfo:b',
      ]);
      expect(effects.log.where((e) => e.endsWith(':c')), [
        'tom:c',
        'persist:c',
        'userInfo:c',
        'homeserver:c',
        'contacts:c',
        'support:c',
        'presence:c',
        'sentry:c',
      ]);
    });
  });

  group('generation token', () {
    test('stays current through an uninterrupted run', () async {
      boot();
      await switchTo('b');
      expect(effects.checks, [
        'tom:b:true',
        'persist:b:true',
        'userInfo:b:true',
        'homeserver:b:true',
      ]);
    });

    test('a newer switch turns the older token stale after its await, so the '
        'older write never lands', () async {
      effects.gates['userInfo:b'] = Completer<void>();
      boot();
      final first = expectLater(
        switchTo('b'),
        throwsA(isA<SwitchSupersededException>()),
      );
      await pump();
      final second = switchTo('c');
      await pump();
      effects.gates['userInfo:b']!.complete();
      await second;
      await first;
      await settle();

      expect(effects.checks, contains('userInfo:b:false'));
      expect(effects.checks, contains('userInfo:c:true'));
      expect(effects.store, {
        'tom': 'c',
        'persist': 'c',
        'userInfo': 'c',
        'homeserver': 'c',
      });
    });

    test('is already stale when the first awaited step resumes', () async {
      effects.gates['tom:b'] = Completer<void>();
      boot();
      final first = expectLater(
        switchTo('b'),
        throwsA(isA<SwitchSupersededException>()),
      );
      await pump();
      final second = switchTo('c');
      await pump();
      effects.gates['tom:b']!.complete();
      await second;
      await first;
      await settle();

      expect(effects.checks, contains('tom:b:false'));
      expect(effects.store['tom'], 'c');
      expect(effects.log, isNot(contains('persist:b')));
    });

    test('dispose turns the token of a running apply stale', () async {
      effects.gates['userInfo:b'] = Completer<void>();
      boot();
      final switching = expectLater(
        switchTo('b'),
        throwsA(isA<SwitchSupersededException>()),
      );
      await pump();
      coordinator.dispose();
      effects.gates['userInfo:b']!.complete();
      await switching;

      expect(effects.checks, contains('userInfo:b:false'));
      expect(effects.log, isNot(contains('homeserver:b')));
      expect(coordinator.isAppliedTo(b), isFalse);
    });

    test('apply tells whether it ran to the end', () async {
      effects.gates['userInfo:b'] = Completer<void>();
      boot();
      final older = coordinator.apply(b);
      await pump();
      final newer = coordinator.apply(c);
      effects.gates['userInfo:b']!.complete();
      expect(await older, isFalse);
      expect(await newer, isTrue);
      expect(coordinator.isAppliedTo(c), isTrue);
      expect(coordinator.isAppliedTo(b), isFalse);
    });
  });

  group('rollback', () {
    Future<void> applyOrigin() async {
      boot();
      await coordinator.apply(a);
      effects.log.clear();
      effects.checks.clear();
    }

    test('a failed switch ends first, then the origin is applied again so '
        'its configuration is back', () async {
      await applyOrigin();
      effects.failing.add('homeserver:b');
      await expectLater(switchTo('b'), throwsStateError);
      expect(coordinator.isAppliedTo(a), isFalse);
      await settle();

      expect(effects.log, [
        'voip',
        'tom:b',
        'persist:b',
        'userInfo:b',
        'homeserver:b',
        ...fullRunFor('a'),
      ]);
      expect(coordinator.isAppliedTo(a), isTrue);
      expect(effects.store.values.toSet(), {'a'});
      expect((state() as Active).activeId, 'a');
    });

    test('a failing restore is logged, not thrown, and the next activation '
        'applies the origin', () async {
      await applyOrigin();
      effects.failing.add('homeserver');
      await expectLater(switchTo('b'), throwsStateError);
      await settle();
      expect(coordinator.isAppliedTo(a), isFalse);
      expect(coordinator.hasApplied, isFalse);

      effects.failing.clear();
      expect(await coordinator.activateCurrent(), isTrue);
      expect(coordinator.isAppliedTo(a), isTrue);
    });

    test('a failing step is logged once as a failure, its failed restore '
        'only as a warning', () async {
      await applyOrigin();
      effects.failing.add('homeserver');
      Logs().outputEvents.clear();

      await expectLater(switchTo('b'), throwsStateError);
      await settle();

      final events = Logs().outputEvents;
      expect(events.where((e) => e.level == Level.wtf), hasLength(1));
      expect(events.where((e) => e.level == Level.warning), isNotEmpty);
    });

    test('a restore is dropped when another switch starts', () async {
      await applyOrigin();
      effects.failing.add('homeserver:b');
      effects.gates['userInfo:a'] = Completer<void>();
      await expectLater(switchTo('b'), throwsStateError);
      await settle();
      expect(effects.log.last, 'userInfo:a');

      final toC = switchTo('c');
      await pump();
      effects.gates['userInfo:a']!.complete();
      await toC;
      await settle();

      expect((state() as Active).activeId, 'c');
      expect(effects.checks, contains('userInfo:a:false'));
      expect(effects.store.values.toSet(), {'c'});
      expect(effects.log, isNot(contains('homeserver:a')));
    });

    test('switching back to the origin while the switch runs stops it and '
        'applies the origin again', () async {
      await applyOrigin();
      effects.gates['userInfo:b'] = Completer<void>();
      final toB = expectLater(
        switchTo('b'),
        throwsA(isA<SwitchSupersededException>()),
      );
      await pump();
      expect(effects.store['tom'], 'b');

      await switchTo('a');
      effects.gates['userInfo:b']!.complete();
      await toB;
      await settle();

      expect((state() as Active).activeId, 'a');
      expect(effects.checks, contains('userInfo:b:false'));
      expect(coordinator.isAppliedTo(a), isTrue);
      expect(effects.store.values.toSet(), {'a'});
      expect(effects.log, isNot(contains('homeserver:b')));
    });

    test('a switch superseded by another one is not rolled back', () async {
      await applyOrigin();
      effects.gates['userInfo:b'] = Completer<void>();
      final toB = expectLater(
        switchTo('b'),
        throwsA(isA<SwitchSupersededException>()),
      );
      await pump();
      final toC = switchTo('c');
      await pump();
      effects.gates['userInfo:b']!.complete();
      await toC;
      await toB;
      await settle();

      expect(effects.log.where((e) => e.endsWith(':a')), isEmpty);
      expect(effects.store.values.toSet(), {'c'});
    });

    test('an account without a client changes nothing, so nothing is '
        'restored', () async {
      await applyOrigin();
      final registry = {'a': a, 'b': b, 'c': c};
      container.dispose();
      boot(clientOf: (id) => id == 'b' ? null : registry[id]);
      await coordinator.apply(a);
      effects.log.clear();
      await expectLater(switchTo('b'), throwsA(isA<UnknownAccountException>()));
      await settle();
      expect(effects.log, isEmpty);
      expect(coordinator.isAppliedTo(a), isTrue);
    });
  });

  group('activateCurrent', () {
    test('does nothing when the active account has no client', () async {
      boot(clientOf: (_) => null);

      expect(await coordinator.activateCurrent(), isFalse);
      expect(effects.log, isEmpty);
    });

    test('starting twice registers one switch handler', () {
      boot();
      final accounts = container.read(accountsProvider.notifier);
      coordinator.start();

      expect(accounts.registerSwitchHandler, throwsA(isA<AssertionError>()));

      coordinator.dispose();

      expect(accounts.registerSwitchHandler, returnsNormally);
    });

    test('a run for another account does not stop the activation of the '
        'active one', () async {
      effects.gates['tom:b'] = Completer<void>();
      boot();
      final other = coordinator.apply(b);
      await pump();

      expect(await coordinator.activateCurrent(), isTrue);
      effects.gates['tom:b']!.complete();

      expect(await other, isFalse);
      expect(coordinator.isAppliedTo(a), isTrue);
    });

    test('applies the active account once; later calls are no-ops', () async {
      boot();
      expect(await coordinator.activateCurrent(), isTrue);
      expect(effects.log, fullRunFor('a'));
      expect(coordinator.isAppliedTo(a), isTrue);

      expect(await coordinator.activateCurrent(), isFalse);
      expect(effects.log, fullRunFor('a'));
    });

    test('concurrent calls share one run', () async {
      effects.gates['tom:a'] = Completer<void>();
      boot();
      final first = coordinator.activateCurrent();
      final second = coordinator.activateCurrent();
      await pump();
      effects.gates['tom:a']!.complete();

      expect(await first, isTrue);
      expect(await second, isTrue);
      expect(effects.log, fullRunFor('a'));
    });

    test('during a switch it waits for it and does not run twice', () async {
      effects.gates['homeserver:b'] = Completer<void>();
      boot();
      final switching = switchTo('b');
      await pump();
      final activation = coordinator.activateCurrent();
      await pump();
      effects.gates['homeserver:b']!.complete();
      await switching;

      expect(await activation, isFalse);
      expect(effects.log, fullRunFor('b'));
      expect(coordinator.isAppliedTo(b), isTrue);
    });

    test('does nothing without an active account', () async {
      boot(clients: []);
      expect(state(), isA<NoAccount>());
      expect(await coordinator.activateCurrent(), isFalse);
      expect(effects.log, isEmpty);
    });

    test('first login: runs the full order once, the later call from the '
        'scaffold does nothing', () async {
      final first = LoginableClient('a', userID: '@a:s');
      boot(clients: [first]);
      expect(state(), isA<NoAccount>());
      first.loggedIn = true;
      await container
          .read(accountsProvider.notifier)
          .addAccount(const AccountId('a'));
      expect((state() as Active).activeId, 'a');

      expect(await coordinator.activateCurrent(), isTrue);
      expect(effects.log, fullRunFor('a'));
      expect(await coordinator.activateCurrent(), isFalse);
      expect(effects.log, fullRunFor('a'));
    });
  });

  group('logout of the last account', () {
    test(
      'with only waiting accounts left, nothing is applied any more',
      () async {
        boot();
        final accounts = container.read(accountsProvider.notifier);
        await accounts.holdRemoval(const AccountId('b'));
        await accounts.holdRemoval(const AccountId('c'));
        expect(await coordinator.activateCurrent(), isTrue);

        accounts.logoutLast();

        expect(state(), isA<NoAccount>());
        expect(coordinator.hasApplied, isFalse);
      },
    );

    test('logging in again applies the effects again', () async {
      final only = LoginableClient('a', userID: '@a:s')..loggedIn = true;
      boot(clients: [only]);
      expect(await coordinator.activateCurrent(), isTrue);
      effects.log.clear();

      only.loggedIn = false;
      container.read(accountsProvider.notifier).logoutLast();
      expect(state(), isA<LastLoggedOut>());
      expect(coordinator.hasApplied, isFalse);
      expect(coordinator.isAppliedTo(only), isFalse);

      only.loggedIn = true;
      await container
          .read(accountsProvider.notifier)
          .addAccount(const AccountId('a'));
      expect(await coordinator.activateCurrent(), isTrue);
      expect(effects.log, fullRunFor('a'));
      expect(coordinator.isAppliedTo(only), isTrue);
    });

    test('a run still going when the account logs out cannot mark it '
        'applied', () async {
      final only = LoginableClient('a', userID: '@a:s')..loggedIn = true;
      effects.gates['userInfo:a'] = Completer<void>();
      boot(clients: [only]);
      final activation = coordinator.activateCurrent();
      await pump();

      only.loggedIn = false;
      container.read(accountsProvider.notifier).logoutLast();
      effects.gates['userInfo:a']!.complete();
      expect(await activation, isFalse);

      expect(coordinator.hasApplied, isFalse);
      expect(effects.log, isNot(contains('homeserver:a')));
    });
  });

  group('same-target switches', () {
    test(
      'the end of an older switch to b does not end a newer one to b',
      () async {
        boot();
        await coordinator.apply(a);
        effects.log.clear();
        final first = Completer<void>();
        final second = Completer<void>();
        effects.gates['tom:b'] = first;

        final toB = expectLater(
          switchTo('b'),
          throwsA(isA<SwitchSupersededException>()),
        );
        await pump();
        await switchTo('a');
        effects.gates['tom:b'] = second;
        var done = false;
        final againToB = switchTo('b').then((_) => done = true);
        await pump();

        first.complete();
        await toB;
        await settle();
        expect(done, isFalse);
        expect(state(), isA<Switching>());

        second.complete();
        await againToB;
        expect((state() as Active).activeId, 'b');
        expect(coordinator.isAppliedTo(b), isTrue);
      },
    );

    test('the failure of an older switch to b does not fail a newer one to '
        'b', () async {
      boot();
      await coordinator.apply(a);
      effects.log.clear();
      final first = Completer<void>();
      final second = Completer<void>();
      effects.gates['tom:b'] = first;
      effects.failing.add('persist:b');

      final toB = expectLater(
        switchTo('b'),
        throwsA(isA<SwitchSupersededException>()),
      );
      await pump();
      await switchTo('a');
      effects.failing.clear();
      effects.gates['tom:b'] = second;
      final againToB = switchTo('b');
      await pump();

      first.complete();
      await toB;
      await settle();
      expect(state(), isA<Switching>());

      second.complete();
      await againToB;
      expect((state() as Active).activeId, 'b');
    });
  });

  group('first activation and lifecycle', () {
    test(
      'apply runs the effects for the active account with no switch',
      () async {
        boot();
        expect(coordinator.hasApplied, isFalse);
        expect(await coordinator.apply(a), isTrue);
        expect(effects.log, fullRunFor('a'));
        expect(coordinator.hasApplied, isTrue);
        expect((state() as Active).activeId, 'a');
      },
    );

    test('after dispose no run starts, even when called directly', () async {
      boot();
      coordinator.dispose();

      expect(await coordinator.apply(a), isFalse);
      expect(await coordinator.activateCurrent(), isFalse);
      await coordinator.onAccountsChanged(
        null,
        Switching(
          accounts: (state() as Active).accounts,
          from: 'a',
          to: 'b',
          seq: 1,
        ),
      );
      expect(effects.log, isEmpty);
    });

    test('after dispose no effect runs and a switch ends at once', () async {
      boot();
      subscription.close();
      coordinator.dispose();
      await switchTo('b');
      expect(effects.log, isEmpty);
      expect((state() as Active).activeId, 'b');
    });
  });

  group('invariants after every outcome', () {
    void expectResting() {
      expect(coordinator.target, isNull);
      final current = state();
      if (current is LastLoggedOut || current is NoAccount) {
        expect(coordinator.hasApplied, isFalse);
      }
      if (current is Active) {
        final active = {'a': a, 'b': b, 'c': c}[current.activeId]!;
        expect(
          !coordinator.hasApplied || coordinator.isAppliedTo(active),
          isTrue,
          reason: 'what is applied is the active account, or nothing',
        );
      }
    }

    final outcomes = <String, Future<void> Function()>{
      'a switch that works': () => switchTo('b'),
      'a step that throws': () async {
        effects.failing.add('homeserver:b');
        await expectLater(switchTo('b'), throwsStateError);
      },
      'a switch replaced by a newer one': () async {
        effects.gates['tom:b'] = Completer<void>();
        final first = expectLater(
          switchTo('b'),
          throwsA(isA<SwitchSupersededException>()),
        );
        await pump();
        final second = switchTo('c');
        effects.gates['tom:b']!.complete();
        await first;
        await second;
      },
      'the last account logging out': () async {
        container.read(accountsProvider.notifier).logoutLast();
      },
    };
    // Logging out is only possible with one account left.
    const singleAccount = {'the last account logging out'};

    for (final applied in [false, true]) {
      for (final outcome in outcomes.entries) {
        test(
          '${outcome.key}, starting ${applied ? 'applied' : 'unapplied'}',
          () async {
            boot(clients: singleAccount.contains(outcome.key) ? [a] : null);
            if (applied) await coordinator.activateCurrent();

            await outcome.value();
            await settle();

            expectResting();
          },
        );
      }
    }
  });
}
