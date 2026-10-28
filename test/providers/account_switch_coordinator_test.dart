import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/domain/account/entities/account_boot_snapshot.dart';
import 'package:twake_chat/domain/account/entities/account_id.dart';
import 'package:twake_chat/domain/account/entities/accounts_state.dart';
import 'package:twake_chat/domain/account/exceptions/account_exception.dart';
import 'package:twake_chat/providers/account_boot_snapshot_provider.dart';
import 'package:twake_chat/providers/account_repository_provider.dart';
import 'package:twake_chat/providers/account_switch_coordinator.dart';
import 'package:twake_chat/providers/account_switch_effects_provider.dart';
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

  /// What a step in [failing] throws, by `name` or `name:account`; a
  /// [StateError] when none is set.
  final errors = <String, Object>{};

  Future<void> _step(String name, Client client, SwitchToken token) async {
    final id = client.clientName;
    log.add('$name:$id');
    if (failing.contains(name) || failing.contains('$name:$id')) {
      throw errors[name] ?? errors['$name:$id'] ?? StateError('$name failed');
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

  /// Wires the coordinator as `MatrixState.initState` does: sets the effects,
  /// then reads the provider.
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
        if (clientOf != null)
          accountSwitchCoordinatorProvider.overrideWith(
            (ref) => AccountSwitchCoordinator(ref, clientOf: clientOf),
          ),
      ],
    );
    container.read(accountSwitchEffectsHolderProvider.notifier).set(effects);
    container.read(accountsProvider);
    coordinator = container.read(accountSwitchCoordinatorProvider);
  }

  AccountsState state() => container.read(accountsProvider);
  Future<void> switchTo(String id) =>
      container.read(accountsProvider.notifier).switchTo(AccountId(id));
  Future<void> pump() => Future<void>.delayed(Duration.zero);

  /// Lets the background work that nobody awaits (a restore) run to its end.
  Future<void> settle() => pumpEventQueue();

  Future<void> expectFailedSwitch(Matcher error) async {
    await expectLater(switchTo('b'), error);
    await settle();
  }

  /// Starts a switch to [id] that waits at the step [gate] (opened by [held],
  /// or by the test through `effects.gates`). The test makes another switch
  /// replace it, so it ends superseded.
  Future<void> supersededSwitchHeldAt(
    String gate,
    String id, [
    Completer<void>? held,
  ]) {
    effects.gates[gate] = held ?? Completer<void>();
    return expectLater(switchTo(id), throwsA(isA<SwitchSupersededException>()));
  }

  /// A switch to b waits at [gate]; a switch to c replaces it; the gate opens.
  Future<void> replaceHeldSwitchToB(String gate) async {
    final first = supersededSwitchHeldAt(gate, 'b');
    await pump();
    final second = switchTo('c');
    await pump();
    effects.gates[gate]!.complete();
    await second;
    await first;
    await settle();
  }

  /// Boots with a applied and nothing recorded yet.
  Future<void> bootApplied() async {
    boot();
    await coordinator.apply(a);
    effects.log.clear();
    effects.checks.clear();
  }

  /// The failed switch left the origin `a` active, applied again and alone in
  /// the shared state.
  void expectOriginRestored() {
    expect(coordinator.isAppliedTo(a), isTrue);
    expect(effects.store.values.toSet(), {'a'});
    expect((state() as Active).activeId, 'a');
  }

  /// The origin `a` ran no step and the shared state holds only [id].
  void expectOriginUntouchedAndStoreOn(String id) {
    expect(effects.log.where((e) => e.endsWith(':a')), isEmpty);
    expect(effects.store.values.toSet(), {id});
  }

  void expectNotAppliedFor(Client client, {Client? pending}) {
    expect(coordinator.hasApplied, isFalse);
    expect(coordinator.isAppliedTo(client), isFalse);
    expect(coordinator.target, pending == null ? isNull : same(pending));
  }

  /// The failed switch left the origin `a` active and did not apply it again.
  Future<void> expectOriginNotRestored(Future<void> failedSwitch) async {
    await failedSwitch;
    await settle();
    expect(effects.log.where((e) => e.endsWith(':a')), isEmpty);
    expect((state() as Active).activeId, 'a');
  }

  /// [client] is the active account and its effects run once, in full.
  Future<void> expectActivationRunsOnce(Client client) async {
    expect(await coordinator.activateCurrent(), isTrue);
    expect(effects.log, fullRunFor(client.clientName));
    expect(coordinator.isAppliedTo(client), isTrue);
  }

  /// An older switch to b waits at `tom` ([first]); a switch back to a ends
  /// it, and a newer switch to b waits at the same step ([second]). The
  /// failures set before are cleared once the older one is replaced.
  Future<({Future<void> older, Future<void> newer})> holdOlderAndNewerToB(
    Completer<void> first,
    Completer<void> second,
  ) async {
    final older = supersededSwitchHeldAt('tom:b', 'b', first);
    await pump();
    await switchTo('a');
    effects.failing.clear();
    effects.gates['tom:b'] = second;
    final newer = switchTo('b');
    await pump();
    return (older: older, newer: newer);
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    effects = FakeSwitchEffects();
    a = FakeAccountClient('a', userID: '@a:s');
    b = FakeAccountClient('b', userID: '@b:s');
    c = FakeAccountClient('c', userID: '@c:s');
  });

  group('order', () {
    test('moves from not applied, to applying, to applied, then resets after '
        'the last logout', () async {
      final only = LoginableClient('a', userID: '@a:s')..loggedIn = true;
      effects.gates['tom:a'] = Completer<void>();
      boot(clients: [only]);

      final applying = coordinator.activateCurrent();
      await pump();
      expectNotAppliedFor(only, pending: only);

      effects.gates['tom:a']!.complete();
      expect(await applying, isTrue);
      expect(coordinator.hasApplied, isTrue);
      expect(coordinator.isAppliedTo(only), isTrue);
      expect(coordinator.target, isNull);

      only.loggedIn = false;
      await container.read(accountsProvider.notifier).logoutLast();

      expectNotAppliedFor(only);
    });

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
      await expectOriginNotRestored(
        expectLater(switchTo('b'), throwsStateError),
      );

      expect(coordinator.hasApplied, isFalse);
    });

    test('an origin applied before a failed switch is restored even when '
        'the switch was retried first', () async {
      await bootApplied();
      effects.failing.add('homeserver:c');
      final first = supersededSwitchHeldAt('tom:b', 'b');
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
        boot();
        Logs().outputEvents.clear();

        await replaceHeldSwitchToB('userInfo');

        expect(Logs().outputEvents.where((e) => e.level == Level.wtf), isEmpty);
      },
    );

    test('a newer switch wins; the older effects stop at their next '
        'checkpoint', () async {
      boot();
      final firstResult = supersededSwitchHeldAt('userInfo', 'b');
      await pump();
      expect(effects.log.last, 'userInfo:b');

      final second = switchTo('c');
      await pump();
      effects.gates['userInfo']!.complete();
      await second;
      await firstResult;
      await pump();

      expect((state() as Active).activeId, 'c');
      expectOriginUntouchedAndStoreOn('c');
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
      boot();
      await replaceHeldSwitchToB('userInfo:b');

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
      boot();
      await replaceHeldSwitchToB('tom:b');

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
    test('a failed switch ends first, then the origin is applied again so '
        'its configuration is back', () async {
      await bootApplied();
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
      expectOriginRestored();
    });

    test('a failing restore is logged, not thrown, and the next activation '
        'applies the origin', () async {
      await bootApplied();
      effects.failing.add('homeserver');
      await expectFailedSwitch(throwsStateError);
      expect(coordinator.isAppliedTo(a), isFalse);
      expect(coordinator.hasApplied, isFalse);

      effects.failing.clear();
      expect(await coordinator.activateCurrent(), isTrue);
      expect(coordinator.isAppliedTo(a), isTrue);
    });

    test('a failing step is logged once as a failure, its failed restore '
        'only as a warning', () async {
      await bootApplied();
      effects.failing.add('homeserver');
      Logs().outputEvents.clear();

      await expectLater(switchTo('b'), throwsStateError);
      await settle();

      final events = Logs().outputEvents;
      expect(events.where((e) => e.level == Level.wtf), hasLength(1));
      expect(events.where((e) => e.level == Level.warning), isNotEmpty);
    });

    for (final offline in <Object>[
      const SocketException('offline'),
      TimeoutException('offline'),
      http.ClientException('offline'),
    ]) {
      test('a switch that fails because of ${offline.runtimeType} is logged '
          'as a warning, not as a failure', () async {
        await bootApplied();
        effects.failing.add('homeserver:b');
        effects.errors['homeserver:b'] = offline;
        Logs().outputEvents.clear();

        await expectFailedSwitch(throwsA(same(offline)));

        final events = Logs().outputEvents;
        expect([
          for (final event in events)
            if (event.level == Level.wtf) event,
        ], isEmpty);
        expect([
          for (final event in events)
            if (event.level == Level.warning &&
                event.title.contains('switch failed'))
              event,
        ], hasLength(1));
      });
    }

    test('a restore is dropped when another switch starts', () async {
      await bootApplied();
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
      await bootApplied();
      final toB = supersededSwitchHeldAt('userInfo:b', 'b');
      await pump();
      expect(effects.store['tom'], 'b');

      await switchTo('a');
      effects.gates['userInfo:b']!.complete();
      await toB;
      await settle();

      expect(effects.checks, contains('userInfo:b:false'));
      expectOriginRestored();
      expect(effects.log, isNot(contains('homeserver:b')));
    });

    test('a switch superseded by another one is not rolled back', () async {
      await bootApplied();
      await replaceHeldSwitchToB('userInfo:b');

      expectOriginUntouchedAndStoreOn('c');
    });

    test('an origin that never had a client is not restored after a failed '
        'switch', () async {
      final registry = {'b': b, 'c': c};
      boot(clientOf: (id) => registry[id]);
      effects.failing.add('homeserver:b');

      await expectOriginNotRestored(
        expectLater(switchTo('b'), throwsStateError),
      );
    });

    test('an origin whose client is gone when the switch fails is not '
        'restored', () async {
      var originGone = false;
      final registry = {'a': a, 'b': b, 'c': c};
      boot(clientOf: (id) => originGone && id == 'a' ? null : registry[id]);
      await coordinator.apply(a);
      effects.log.clear();
      effects.failing.add('persist:b');
      effects.gates['tom:b'] = Completer<void>();

      final failed = expectLater(switchTo('b'), throwsStateError);
      await pump();
      originGone = true;
      effects.gates['tom:b']!.complete();
      await expectOriginNotRestored(failed);
    });

    test('an account without a client changes nothing, so nothing is '
        'restored', () async {
      await bootApplied();
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
      await expectActivationRunsOnce(a);

      expect(await coordinator.activateCurrent(), isFalse);
      expect(effects.log, fullRunFor('a'));
    });

    test(
      'a cancelled run is not reused; activateCurrent still applies',
      () async {
        effects.gates['tom:a'] = Completer<void>();
        var hideB = false;
        boot(
          clientOf: (id) {
            if (hideB && id == 'b') return null;
            return {'a': a, 'b': b, 'c': c}[id];
          },
        );
        final cancelled = coordinator.activateCurrent();
        await pump();

        hideB = true;
        await expectLater(
          switchTo('b'),
          throwsA(isA<UnknownAccountException>()),
        );
        hideB = false;
        effects.log.clear();

        final again = coordinator.activateCurrent();
        await pump();
        effects.gates['tom:a']!.complete();

        expect(await again, isTrue);
        expect(await cancelled, isFalse);
        expect(coordinator.isAppliedTo(a), isTrue);
        expect(effects.log, fullRunFor('a'));
      },
    );

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

      await expectActivationRunsOnce(first);
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

        await accounts.logoutLast();

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
      await container.read(accountsProvider.notifier).logoutLast();
      expect(state(), isA<LastLoggedOut>());
      expect(coordinator.hasApplied, isFalse);
      expect(coordinator.isAppliedTo(only), isFalse);

      only.loggedIn = true;
      await container
          .read(accountsProvider.notifier)
          .addAccount(const AccountId('a'));
      await expectActivationRunsOnce(only);
    });

    test('a run still going when the account logs out cannot mark it '
        'applied', () async {
      final only = LoginableClient('a', userID: '@a:s')..loggedIn = true;
      effects.gates['userInfo:a'] = Completer<void>();
      boot(clients: [only]);
      final activation = coordinator.activateCurrent();
      await pump();

      only.loggedIn = false;
      await container.read(accountsProvider.notifier).logoutLast();
      effects.gates['userInfo:a']!.complete();
      expect(await activation, isFalse);

      expect(coordinator.hasApplied, isFalse);
      expect(effects.log, isNot(contains('homeserver:a')));
    });
  });

  group('same-target switches', () {
    // The failing step is cleared before the older switch resumes, as the
    // older one stops at its token check without reaching it.
    const cases = {
      'the end of an older switch to b does not end a newer one to b': false,
      'the failure of an older switch to b does not fail a newer one to b':
          true,
    };
    for (final entry in cases.entries) {
      test(entry.key, () async {
        await bootApplied();
        final first = Completer<void>();
        final second = Completer<void>();
        if (entry.value) effects.failing.add('persist:b');

        final held = await holdOlderAndNewerToB(first, second);
        var done = false;
        final againToB = held.newer.then((_) => done = true);

        first.complete();
        await held.older;
        await settle();
        expect(done, isFalse);
        expect(state(), isA<Switching>());

        second.complete();
        await againToB;
        expect((state() as Active).activeId, 'b');
        expect(coordinator.isAppliedTo(b), isTrue);
      });
    }
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
        final first = supersededSwitchHeldAt('tom:b', 'b');
        await pump();
        final second = switchTo('c');
        effects.gates['tom:b']!.complete();
        await first;
        await second;
      },
      'the last account logging out': () async {
        await container.read(accountsProvider.notifier).logoutLast();
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
