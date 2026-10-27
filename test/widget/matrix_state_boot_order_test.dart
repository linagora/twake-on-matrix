import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:matrix/encryption.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/config/localizations/localization_service.dart';
import 'package:twake_chat/data/local/localizations/language_cache_manager.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/model/user_info/user_info.dart';
import 'package:twake_chat/domain/repository/user_info/user_info_repository.dart';
import 'package:twake_chat/domain/contact/sources/phonebook_resolver.dart';
import 'package:twake_chat/pages/contacts_tab/providers/contacts_providers.dart';
import 'package:twake_chat/utils/network_connection_service.dart';
import 'package:twake_chat/data/account/logout_removals.dart';
import 'package:twake_chat/data/network/interceptor/authorization_interceptor.dart';
import 'package:twake_chat/data/network/interceptor/dynamic_url_interceptor.dart';
import 'package:twake_chat/di/global/network_di.dart';
import 'package:twake_chat/domain/account/entities/account_boot_snapshot.dart';
import 'package:twake_chat/domain/model/homeserver_summary.dart';
import 'package:twake_chat/domain/model/tom_configurations.dart';
import 'package:twake_chat/domain/model/tom_server_information.dart';
import 'package:twake_chat/domain/repository/tom_configurations_repository.dart';
import 'package:twake_chat/providers/account_services_providers.dart';
import 'package:twake_chat/providers/account_switch_coordinator.dart';
import 'package:twake_chat/providers/account_switch_effects_provider.dart';
import 'package:twake_chat/providers/push_removals_controller.dart';
import 'package:twake_chat/providers/account_boot_snapshot_provider.dart';
import 'package:twake_chat/providers/account_repository_provider.dart';
import 'package:twake_chat/providers/boot_clients_provider.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:twake_chat/widgets/set_active_client_state.dart';

import '../data/account/fakes.dart';

/// Remembers that something listened to its stream.
class _WatchedController<T> extends CachedStreamController<T> {
  bool listened = false;

  @override
  Stream<T> get stream {
    listened = true;
    return super.stream;
  }
}

/// A client with the streams and the http client `MatrixState` opens at boot.
class _BootClient extends FakeAccountClient {
  _BootClient(super.clientName, {super.userID});

  final _onRoomKeyRequest = CachedStreamController<RoomKeyRequest>();
  final _onKeyVerificationRequest = CachedStreamController<KeyVerification>();
  final _onLoginStateChanged = _WatchedController<LoginState>();
  final _onUiaRequest = CachedStreamController<UiaRequest>();
  final _onSyncStatus = CachedStreamController<SyncStatusUpdate>();
  final _onToDeviceEvent = CachedStreamController<ToDeviceEvent>();
  final _httpClient = http.Client();

  @override
  CachedStreamController<RoomKeyRequest> get onRoomKeyRequest =>
      _onRoomKeyRequest;

  @override
  CachedStreamController<KeyVerification> get onKeyVerificationRequest =>
      _onKeyVerificationRequest;

  @override
  _WatchedController<LoginState> get onLoginStateChanged =>
      _onLoginStateChanged;

  @override
  CachedStreamController<UiaRequest> get onUiaRequest => _onUiaRequest;

  @override
  CachedStreamController<SyncStatusUpdate> get onSyncStatus => _onSyncStatus;

  @override
  CachedStreamController<ToDeviceEvent> get onToDeviceEvent => _onToDeviceEvent;

  @override
  http.Client get httpClient => _httpClient;
}

/// A client whose subscriptions cannot be registered.
class _BrokenBootClient extends _BootClient {
  _BrokenBootClient(super.clientName, {super.userID});

  @override
  CachedStreamController<RoomKeyRequest> get onRoomKeyRequest =>
      throw StateError('broken client');
}

/// A client with an access token and no homeserver, which is all the ToM
/// set-up of a switch reads.
class _ToMClient extends _BootClient {
  _ToMClient(super.clientName, {super.userID});

  @override
  String? get accessToken => 'token-$clientName';

  @override
  Uri? get homeserver => null;
}

/// Stores a ToM configuration for the accounts it was given and, like the real
/// repository, throws for any other.
class _FakeToMConfigurationsRepository extends Fake
    implements ToMConfigurationsRepository {
  _FakeToMConfigurationsRepository(this.stored);

  final Map<String, ToMConfigurations> stored;
  final saved = <String, ToMConfigurations>{};

  @override
  Future<ToMConfigurations> getTomConfigurations(String userId) async =>
      stored[userId] ?? (throw StateError('no ToM configuration for $userId'));

  @override
  Future<void> saveTomConfigurations(
    String userId,
    ToMConfigurations toMConfigurations,
  ) async => saved[userId] = toMConfigurations;
}

/// Like [_FakeToMConfigurationsRepository], but once its [hold] is armed, the
/// second read of [gatedId] waits for it and then returns [lateValue], or finds
/// nothing when there is none: the fallback read of a switch that a newer one
/// supersedes meanwhile.
class _GatedToMConfigurationsRepository
    extends _FakeToMConfigurationsRepository {
  _GatedToMConfigurationsRepository(
    super.stored, {
    required this.gatedId,
    this.lateValue,
  });

  final String gatedId;
  final ToMConfigurations? lateValue;
  final hold = _Hold();
  int _reads = 0;

  @override
  Future<ToMConfigurations> getTomConfigurations(String userId) async {
    if (!hold.armed || userId != gatedId || ++_reads < 2) {
      return super.getTomConfigurations(userId);
    }
    await hold.pass();
    return lateValue ?? (throw StateError('no ToM configuration for $userId'));
  }
}

/// Holds the read that reaches it once [armed], until [gate] completes.
class _Hold {
  // Sync: the test body creates them outside the real async zone it awaits in.
  final gate = Completer<void>.sync();
  final reached = Completer<void>.sync();
  bool armed = false;

  Future<void> pass() {
    reached.complete();
    return gate.future;
  }
}

/// The server language of each account.
class _FakeUserInfoRepository extends Fake implements UserInfoRepository {
  _FakeUserInfoRepository(this.languages);

  final Map<String, String> languages;

  @override
  Future<UserInfo> getUserInfo(String userId) async =>
      UserInfo(language: languages[Uri.decodeComponent(userId)]);
}

/// Once its [hold] is armed, the first read of the stored language waits for
/// it.
class _GatedLanguageCacheManager extends Fake implements LanguageCacheManager {
  final hold = _Hold();

  @override
  Future<Locale?> getStoredLanguage() async {
    if (hold.armed && !hold.reached.isCompleted) await hold.pass();
    return null;
  }
}

/// The switch effects with only the ToM set-up of `MatrixState`: it is the one
/// step under test and the others need the whole app wiring.
class _ToMOnlyEffects implements AccountSwitchEffects {
  _ToMOnlyEffects(this.matrix);

  final MatrixState matrix;

  @override
  Future<void> setUpToM(Client client, SwitchToken token) =>
      matrix.setUpToM(client, token);

  @override
  void createVoipPlugin() {}

  @override
  Future<void> persistActiveAccount(Client client, SwitchToken token) async {}

  @override
  Future<void> loadUserInfo(Client client, SwitchToken token) async {}

  @override
  Future<void> loadHomeserverInfo(Client client, SwitchToken token) async {}

  @override
  void refreshContacts(Client client) {}

  @override
  void createSupportChat(Client client) {}

  @override
  void listenPresence(Client client) {}

  @override
  void configureSentryUser(Client client) {}
}

/// The switch effects with only the user info step of `MatrixState`.
class _UserInfoOnlyEffects extends _ToMOnlyEffects {
  _UserInfoOnlyEffects(super.matrix);

  @override
  Future<void> setUpToM(Client client, SwitchToken token) async {}

  @override
  Future<void> loadUserInfo(Client client, SwitchToken token) =>
      matrix.loadUserInfo(client, token);
}

/// Registers the interceptors the ToM set-up writes and [repository]; returns
/// the ToM server interceptor.
DynamicUrlInterceptors _registerToM(
  ToMConfigurationsRepository repository, {
  AuthorizationInterceptor? authorization,
}) {
  final tomServer = DynamicUrlInterceptors();
  getIt
    ..registerSingleton<DynamicUrlInterceptors>(
      tomServer,
      instanceName: NetworkDI.tomServerUrlInterceptorName,
    )
    ..registerSingleton<DynamicUrlInterceptors>(
      DynamicUrlInterceptors(),
      instanceName: NetworkDI.homeServerUrlInterceptorName,
    )
    ..registerSingleton<DynamicUrlInterceptors>(
      DynamicUrlInterceptors(),
      instanceName: NetworkDI.identityServerUrlInterceptorName,
    )
    ..registerSingleton<AuthorizationInterceptor>(
      authorization ?? AuthorizationInterceptor(),
    )
    ..registerSingleton<ToMConfigurationsRepository>(repository);
  return tomServer;
}

ToMConfigurations _toM(String url) => ToMConfigurations(
  tomServerInformation: ToMServerInformation(baseUrl: Uri.parse(url)),
);

String _languageCode() => LocalizationService.currentLocale.value.languageCode;

/// Waits, in real time, until [done] holds.
Future<void> _until(bool Function() done) async {
  for (var i = 0; i < 100 && !done(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

/// `setActiveClient` stops the contacts lookup of the account being left.
class _NoopPhonebookResolver extends Fake implements PhonebookResolver {
  @override
  Future<void> cancel() async {}
}

/// Mounts `Matrix` over a container that `main` would have built: the boot
/// clients and the persisted state are overridden.
class _Harness {
  _Harness(
    this.tester,
    this.clients, {
    AccountBootSnapshot snapshot = const AccountBootSnapshot(),
    List<Override> overrides = const [],
  }) : container = ProviderContainer(
         retry: (_, _) => null,
         overrides: [
           accountClientDataSourceProvider.overrideWithValue(
             FakeAccountClientDataSource(),
           ),
           bootClientsProvider.overrideWithValue(clients),
           bootAccountSnapshotProvider.overrideWithValue(snapshot),
           ...overrides,
         ],
       ) {
    addTearDown(container.dispose);
  }

  final WidgetTester tester;
  final List<Client> clients;
  final ProviderContainer container;

  MatrixState get matrix => tester.state<MatrixState>(find.byType(Matrix));

  /// The post-frame `initMatrix` needs the whole app wiring, which these tests
  /// do not cover: its failures are dropped, what the tests read is set by
  /// `initState` and by the subscriptions of `initMatrix`.
  Future<void> run(Future<void> Function() body) async {
    await runZonedGuarded(body, (_, _) {});
  }

  Future<void> mount() => tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Matrix(clients: clients, child: const SizedBox()),
      ),
    ),
  );

  Future<void> unmount() async {
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const SizedBox()),
    );
    await tester.pump();
  }

  /// Mounts, lets the boot run, then makes [effects] the switch effects.
  Future<AccountSwitchCoordinator> switchingWith(
    AccountSwitchEffects Function(MatrixState matrix) effects,
  ) async {
    await mount();
    await settle();
    container.read(accountSwitchEffectsProvider.notifier).set(effects(matrix));
    return container.read(accountSwitchCoordinatorProvider);
  }

  /// Lets the real async work of `initMatrix` and of the handlers run.
  Future<void> settle() =>
      tester.runAsync(() => Future<void>.delayed(Duration.zero));
}

/// A switch from `a` to `b` that [hold] catches in its ToM set-up and that a
/// switch to `c` overtakes before [hold] lets it go.
class _ToMOvertaking {
  _ToMOvertaking(WidgetTester tester, this.hold)
    : harness = _Harness(tester, [
        _ToMClient('a', userID: '@a:s'),
        _ToMClient('b', userID: '@b:s'),
        _ToMClient('c', userID: '@c:s'),
      ]);

  final _Harness harness;
  final _Hold hold;

  /// Runs it; [whenOvertaken] runs once the switch to `c` is done. Returns
  /// whether the switch to `b` applied.
  Future<bool?> run({void Function()? whenOvertaken}) async {
    bool? applied;
    await harness.run(() async {
      final coordinator = await harness.switchingWith(_ToMOnlyEffects.new);

      await harness.tester.runAsync(() async {
        hold.armed = true;
        final superseded = coordinator.apply(harness.clients[1]);
        await hold.reached.future;
        await coordinator.apply(harness.clients[2]);
        whenOvertaken?.call();
        hold.gate.complete();
        applied = await superseded;
      });
    });
    return applied;
  }
}

/// A homeserver summary that announces the ToM server at [url].
HomeserverSummary _summaryWithToM(String url) => HomeserverSummary(
  discoveryInformation: DiscoveryInformation(
    mHomeserver: HomeserverInformation(baseUrl: Uri.parse('https://c')),
    additionalProperties: {
      ToMServerInformation.tomServerKey: {'base_url': url, 'server_name': 'c'},
    },
  ),
  versions: GetVersionsResponse(versions: []),
  loginFlows: [],
);

class _FakeNetworkConnectionService extends Fake
    implements NetworkConnectionService {
  @override
  Stream<ConnectivityResult> getStreamInstance() => const Stream.empty();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    getIt.registerSingleton<NetworkConnectionService>(
      _FakeNetworkConnectionService(),
    );
  });
  tearDown(getIt.reset);

  testWidgets('MatrixState starts on the boot accounts that main overrode', (
    tester,
  ) async {
    final client = _BootClient('a', userID: '@a:s');
    final harness = _Harness(tester, [client]);

    Client? active;
    List<Client>? listed;
    await harness.run(() async {
      await harness.mount();
      active = harness.container.read(activeMatrixClientProvider);
      listed = harness.container.read(accountClientsProvider);
    });

    // The state adopts the boot clients at its first read, whichever
    // provider is read first.
    expect(active, same(client));
    expect(listed, [client]);
  });

  testWidgets('setActiveClient tells an account that waits for its removal '
      'from an unknown one', (tester) async {
    final active = _BootClient('a', userID: '@a:s');
    final waiting = _BootClient('b', userID: '@b:s');
    final harness = _Harness(
      tester,
      [active, waiting],
      snapshot: const AccountBootSnapshot(pendingRemovalIds: {'b'}),
      overrides: [
        phonebookResolverProvider.overrideWithValue(_NoopPhonebookResolver()),
      ],
    );

    SetActiveClientState? known;
    SetActiveClientState? unknown;
    await harness.run(() async {
      await harness.mount();
      final matrix = harness.matrix;
      known = await tester.runAsync(() => matrix.setActiveClient(waiting));
      unknown = await tester.runAsync(
        () => matrix.setActiveClient(_BootClient('x', userID: '@x:s')),
      );
    });

    expect(known, SetActiveClientState.unavailable);
    expect(unknown, SetActiveClientState.unknownClient);
  });

  testWidgets('a new session of an account drops its kept pusher deletion', (
    tester,
  ) async {
    final client = _BootClient('a', userID: '@a:s');
    final pushRemovals = LogoutRemovals();
    addTearDown(pushRemovals.dispose);
    final harness = _Harness(
      tester,
      [client],
      overrides: [pushRemovalsProvider.overrideWithValue(pushRemovals)],
    );
    final repository = harness.container.read(accountRepositoryProvider);
    await tester.runAsync(() async {
      await repository.markPushRemovalPending('a');
      await pushRemovals.remove(
        'a',
        RemovalSteps(
          remove: () async => throw StateError('push'),
          hold: () async {},
          settle: () async {},
        ),
        (_, _, _) {},
      );
    });
    expect(pushRemovals.failedIds, {'a'});

    await harness.run(() async {
      await harness.mount();
      // `initMatrix` listens to the login state of each account.
      await harness.settle();
      client.onLoginStateChanged.add(LoginState.loggedIn);
      await harness.settle();
    });

    expect(pushRemovals.failedIds, isEmpty);
    expect(await tester.runAsync(repository.pendingPushRemovals), isEmpty);
  });

  testWidgets('MatrixState sets the switch effects and the push teardown after '
      'the first build and clears them when it is disposed', (tester) async {
    final harness = _Harness(tester, [_BootClient('a', userID: '@a:s')]);
    final effects = harness.container.read(accountSwitchEffectsProvider);
    expect(effects, isNull);

    await harness.run(() async {
      await harness.mount();
      expect(
        harness.container.read(accountSwitchEffectsProvider),
        same(harness.matrix),
      );
      expect(harness.container.read(pushRemovalsControllerProvider), isNotNull);

      await harness.unmount();
    });

    expect(harness.container.read(accountSwitchEffectsProvider), isNull);
    expect(harness.container.read(pushRemovalsControllerProvider), isNull);
  });

  testWidgets('one account whose subscriptions fail does not stop the boot', (
    tester,
  ) async {
    final healthy = _BootClient('b', userID: '@b:s');
    final harness = _Harness(tester, [
      _BrokenBootClient('a', userID: '@a:s'),
      healthy,
    ]);

    await harness.run(() async {
      await harness.mount();
      await harness.settle();
    });

    // The boot went on to the account after the broken one.
    expect(healthy.onLoginStateChanged.listened, isTrue);
  });

  testWidgets('switching to an account with no stored ToM configuration does '
      'not keep the one of the account being left', (tester) async {
    final left = _ToMClient('a', userID: '@a:s');
    final target = _ToMClient('b', userID: '@b:s');
    final authorization = AuthorizationInterceptor();
    final tomServer = _registerToM(
      _FakeToMConfigurationsRepository({'@a:s': _toM('https://tom.a')}),
      authorization: authorization,
    );
    final harness = _Harness(
      tester,
      [left, target],
      overrides: [
        phonebookResolverProvider.overrideWithValue(_NoopPhonebookResolver()),
      ],
    );

    await harness.run(() async {
      await harness.mount();
      await harness.settle();
      // The boot may have set up the active account; start from a clean state.
      tomServer.changeBaseUrl(null);
      authorization.accessToken = null;
      harness.container
          .read(accountSwitchEffectsProvider.notifier)
          .set(_ToMOnlyEffects(harness.matrix));

      final result = await tester.runAsync(
        () => harness.matrix.setActiveClient(target),
      );
      expect(result, SetActiveClientState.success);
    });

    // The target has no configuration: nothing of account `a` stays bound.
    expect(tomServer.baseUrl, isNull);
    expect(authorization.accessToken, 'token-b');
  });

  testWidgets('a superseded switch does not write the ToM configuration it '
      'read late', (tester) async {
    final repository = _GatedToMConfigurationsRepository(
      {'@c:s': _toM('https://tom.c')},
      gatedId: '@b:s',
      lateValue: _toM('https://tom.b'),
    );
    final tomServer = _registerToM(repository);

    final applied = await _ToMOvertaking(tester, repository.hold).run();

    expect(applied, isFalse);
    expect(tomServer.baseUrl, 'https://tom.c');
  });

  testWidgets('a superseded switch does not store the ToM configuration of the '
      'account that overtook it', (tester) async {
    final repository = _GatedToMConfigurationsRepository({
      '@c:s': _toM('https://tom.c'),
    }, gatedId: '@b:s');
    _registerToM(repository);
    final overtaking = _ToMOvertaking(tester, repository.hold);

    // The newer switch discovered its own ToM server into the summary the
    // fresh-install fallback of the stale one reads next.
    await overtaking.run(
      whenOvertaken: () => overtaking.harness.matrix.loginHomeserverSummary =
          _summaryWithToM('https://tom.c'),
    );

    expect(repository.saved, isEmpty);
  });

  testWidgets('a superseded switch does not write the locale it resolved '
      'late', (tester) async {
    final stale = _BootClient('b', userID: '@b:s');
    final newer = _BootClient('c', userID: '@c:s');
    final languages = _GatedLanguageCacheManager();
    getIt
      ..registerSingleton<UserInfoRepository>(
        _FakeUserInfoRepository({'@b:s': 'fr', '@c:s': 'vi'}),
      )
      ..registerSingleton<LanguageCacheManager>(languages);
    addTearDown(
      () => LocalizationService.currentLocale.value =
          LocalizationService.defaultLocale,
    );
    final harness = _Harness(tester, [
      _BootClient('a', userID: '@a:s'),
      stale,
      newer,
    ]);

    await harness.run(() async {
      final coordinator = await harness.switchingWith(_UserInfoOnlyEffects.new);

      await tester.runAsync(() async {
        languages.hold.armed = true;
        unawaited(coordinator.apply(stale));
        await languages.hold.reached.future;
        // A locale write ends with a reassemble that waits for a frame, which
        // no test pumps: the runs are not awaited, their writes are.
        unawaited(coordinator.apply(newer));
        await _until(() => _languageCode() == 'vi');
        languages.hold.gate.complete();
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
    });

    expect(_languageCode(), 'vi');
  });
}
