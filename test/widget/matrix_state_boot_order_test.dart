import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override, ProviderException;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' show MockClient;
import 'package:matrix/encryption.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/config/localizations/localization_service.dart';
import 'package:twake_chat/domain/app_state/room/create_support_chat_state.dart';
import 'package:twake_chat/domain/usecase/room/create_support_chat_interactor.dart';
import 'package:twake_chat/data/local/localizations/language_cache_manager.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/model/user_info/user_info.dart';
import 'package:twake_chat/domain/repository/user_info/user_info_repository.dart';
import 'package:twake_chat/domain/contact/sources/phonebook_resolver.dart';
import 'package:twake_chat/pages/contacts_tab/providers/contacts_providers.dart';
import 'package:twake_chat/utils/network_connection_service.dart';
import 'package:twake_chat/data/account/client_subscriptions.dart';
import 'package:twake_chat/data/account/login_host.dart';
import 'package:twake_chat/data/account/logout_removals.dart';
import 'package:twake_chat/data/network/interceptor/authorization_interceptor.dart';
import 'package:twake_chat/data/network/interceptor/dynamic_url_interceptor.dart';
import 'package:twake_chat/di/global/network_di.dart';
import 'package:twake_chat/data/hive/hive_collection_tom_database.dart';
import 'package:twake_chat/domain/account/entities/account_boot_snapshot.dart';
import 'package:twake_chat/domain/model/extensions/homeserver_summary_extensions.dart';
import 'package:twake_chat/domain/model/homeserver_summary.dart';
import 'package:twake_chat/domain/model/rtc_focus.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';
import 'package:twake_chat/domain/model/tom_configurations.dart';
import 'package:twake_chat/domain/model/tom_server_information.dart';
import 'package:twake_chat/domain/repository/tom_configurations_repository.dart';
import 'package:twake_chat/providers/account_services_providers.dart';
import 'package:twake_chat/providers/account_switch_coordinator.dart';
import 'package:twake_chat/providers/account_switch_effects_provider.dart';
import 'package:twake_chat/presentation/model/client_login_state_event.dart';
import 'package:twake_chat/providers/push_removals_controller.dart';
import 'package:twake_chat/providers/report_failure_provider.dart';
import 'package:twake_chat/providers/account_boot_snapshot_provider.dart';
import 'package:twake_chat/data/account/repositories/account_repository_impl.provider.dart';
import 'package:twake_chat/data/account/datasources_impl/client_manager_account_data_source.provider.dart';
import 'package:twake_chat/providers/boot_clients_provider.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/providers/matrix_client_provider.dart';
import 'package:twake_chat/data/account/sources/account_client_registry.provider.dart';
import 'package:twake_chat/providers/accounts_provider.dart';
import 'package:twake_chat/data/model/federation_server/federation_configuration.dart';
import 'package:twake_chat/domain/account/entities/account_id.dart';
import 'package:twake_chat/domain/account/entities/accounts_state.dart';
import 'package:twake_chat/domain/account/exceptions/account_exception.dart';
import 'package:twake_chat/domain/repository/federation_configurations_repository.dart';
import 'package:twake_chat/data/repository/federation_configurations_repository_impl.provider.dart';
import 'package:twake_chat/data/repository/tom_configurations_repository_impl.provider.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/widgets/twake_app.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:twake_chat/widgets/set_active_client_state.dart';

import '../data/account/fakes.dart';

/// The channels `MatrixState` talks to on a macOS host: notifications, window
/// lifecycle and Dock badge.
const _macosChannels = [
  'dexterous.com/flutter/local_notifications',
  'app.twake/lifecycle',
  'g123k/flutter_app_badger',
];

/// Remembers that something listened to its stream.
class _WatchedController<T> extends CachedStreamController<T> {
  bool listened = false;

  @override
  Stream<T> get stream {
    listened = true;
    return super.stream;
  }
}

class _CountingToMDatabase implements HiveCollectionToMDatabase {
  int clears = 0;

  @override
  Future<void> clear() async => clears++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
  final _onSync = CachedStreamController<SyncUpdate>();
  final _httpClient = http.Client();

  @override
  set backgroundSync(bool _) {}

  @override
  set syncPresence(PresenceType? _) {}

  @override
  CachedStreamController<SyncUpdate> get onSync => _onSync;

  /// The Dock badge counts the rooms of every client.
  @override
  List<Room> get rooms => const [];

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

  /// A client that has not synced yet. The real getter is a stored batch; the
  /// fake would throw, and on Linux that throw escapes the unawaited
  /// registration.
  @override
  String? get prevBatch => null;
}

/// A client with rooms in its list, all under the default push rules.
class _RoomsBootClient extends _BootClient {
  _RoomsBootClient(super.clientName, {super.userID});

  @override
  List<Room> rooms = const [];

  @override
  PushRuleSet? get globalPushRules => null;
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
  _ToMClient(super.clientName, {super.userID, this.server});

  /// The homeserver of the account; none by default, which skips the
  /// discovery of the switch.
  final Uri? server;

  @override
  String? get accessToken => 'token-$clientName';

  @override
  Uri? get homeserver => server;
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
/// [heldRead]-th read of [gatedId] (the second by default) waits for it and
/// then returns [lateValue], or finds nothing when there is none: the fallback
/// read of a switch that a newer one supersedes meanwhile.
class _GatedToMConfigurationsRepository
    extends _FakeToMConfigurationsRepository {
  _GatedToMConfigurationsRepository(
    super.stored, {
    required this.gatedId,
    this.lateValue,
    this.heldRead = 2,
  });

  final String gatedId;
  final ToMConfigurations? lateValue;
  final int heldRead;
  final hold = _Hold();
  int _reads = 0;

  @override
  Future<ToMConfigurations> getTomConfigurations(String userId) async {
    if (!hold.armed || userId != gatedId || ++_reads < heldRead) {
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

/// Records the accounts it looks the support chat up for, and finds the room
/// `!support-<account>`.
class _RecordingSupportChat extends Fake
    implements CreateSupportChatInteractor {
  final lookedUp = <String>[];

  @override
  Stream<Either<Failure, Success>> execute(
    Client client, {
    DiscoveryInformation? cachedDiscovery,
  }) async* {
    lookedUp.add(client.clientName);
    yield Right(SupportChatExisted(roomId: '!support-${client.clientName}'));
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

  // Sync: an extra await would reorder the switches these effects overtake.
  @override
  Future<void> loadCachedHomeserverInfo(Client client, SwitchToken token) =>
      SynchronousFuture(null);

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

/// The switch effects that note the video call url the app holds when the
/// user info, the first network step, starts.
class _DiscoveryEffects extends _ToMOnlyEffects {
  _DiscoveryEffects(super.matrix);

  String? videoCallUrlAtUserInfo;

  @override
  Future<void> loadCachedHomeserverInfo(Client client, SwitchToken token) =>
      matrix.loadCachedHomeserverInfo(client, token);

  @override
  Future<void> setUpToM(Client client, SwitchToken token) async {}

  @override
  Future<void> loadUserInfo(Client client, SwitchToken token) async =>
      videoCallUrlAtUserInfo = matrix.loginHomeserverSummary?.videoCallBaseUrl;
}

/// A database that holds the well-known [cached] on a previous run.
class _WellKnownDatabase extends Fake implements DatabaseApi {
  _WellKnownDatabase(this.cached);

  final Map<String, Object?> cached;

  @override
  Future<({Map<String, Object?> content, DateTime savedAt})?>
  getCustomCacheObject(String cacheKey) async => cacheKey == 'well_known'
      ? (content: cached, savedAt: DateTime.now())
      : null;
}

/// A client whose database holds the well-known it cached on a previous run.
class _CachedDiscoveryClient extends _ToMClient {
  _CachedDiscoveryClient(
    super.clientName, {
    super.userID,
    super.server,
    required Map<String, Object?> wellKnown,
  }) : database = _WellKnownDatabase(wellKnown);

  @override
  final DatabaseApi database;
}

/// The switch effects with no step of `MatrixState`: records the accounts
/// they were applied to.
class _RecordingEffects extends _ToMOnlyEffects {
  _RecordingEffects(super.matrix);

  final applied = <String>[];

  @override
  Future<void> setUpToM(Client client, SwitchToken token) async =>
      applied.add(client.clientName);
}

/// The switch effects with only the homeserver step of `MatrixState`.
class _HomeserverOnlyEffects extends _ToMOnlyEffects {
  _HomeserverOnlyEffects(super.matrix);

  @override
  Future<void> setUpToM(Client client, SwitchToken token) async {}

  @override
  Future<void> loadHomeserverInfo(Client client, SwitchToken token) =>
      matrix.loadHomeserverInfo(client, token);
}

/// The switch effects whose ToM step, once [hold] is armed, persists the
/// account of `b` only after it was held: with the token of a switch that was
/// overtaken by then. The persist step of the others is the one of
/// `MatrixState`.
class _PersistingEffects extends _ToMOnlyEffects {
  _PersistingEffects(super.matrix, this.hold);

  final _Hold hold;

  @override
  Future<void> setUpToM(Client client, SwitchToken token) async {
    if (client.clientName != 'b' || !hold.armed) return;
    await hold.pass();
    await matrix.persistActiveAccount(client, token);
  }

  @override
  Future<void> persistActiveAccount(Client client, SwitchToken token) =>
      matrix.persistActiveAccount(client, token);
}

/// A client whose well-known names its own homeserver. Once [useNetwork] is
/// called it is not logged in, so the well-known is read from [httpClient]
/// and not from the database, and that read waits for [hold] once armed.
class _WellKnownClient extends _BootClient {
  _WellKnownClient(super.clientName, {super.userID, this.hold});

  final _Hold? hold;
  Uri? _homeserver;
  bool _logged = true;

  late final _answering = MockClient((request) async {
    final held = hold;
    if (held != null && held.armed && !held.reached.isCompleted) {
      await held.pass();
    }
    return http.Response(
      jsonEncode({
        'm.homeserver': {'base_url': 'https://hs.$clientName'},
      }),
      200,
    );
  });

  /// Gives the client its homeserver, as a boot that found one would have.
  void announce() => _homeserver = _announcedBy(clientName);

  @override
  Uri? get homeserver => _homeserver;

  @override
  set homeserver(Uri? value) => _homeserver = value;

  void useNetwork() => _logged = false;

  @override
  bool isLogged() => _logged;

  @override
  http.Client get httpClient => _answering;
}

/// The homeserver that [_WellKnownClient] `name` announces.
Uri _announcedBy(String name) => Uri.parse('https://hs.$name');

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

/// The ToM repository [_registerToM] put in GetIt, for the provider that now
/// builds it natively.
final _tomFromGetIt = tomConfigurationsRepositoryProvider.overrideWith(
  (ref) => getIt.get<ToMConfigurationsRepository>(),
);

ToMConfigurations _toM(String url) => ToMConfigurations(
  tomServerInformation: ToMServerInformation(baseUrl: Uri.parse(url)),
);

String _languageCode() => LocalizationService.currentLocale.value.languageCode;

/// A service of the app wiring that these tests do not register, read
/// directly or through a provider that failed on it.
bool _isMissingWiring(Object error) {
  Object current = error;
  while (current is ProviderException) {
    current = current.exception;
  }
  return current is StateError &&
      current.message.contains('is not registered inside GetIt');
}

/// Waits, in real time, until [done] holds.
Future<void> _until(bool Function() done) async {
  for (var i = 0; i < 100 && !done(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

Future<void> _logoutAndWait(
  _Harness harness,
  _BootClient loggedOut,
  bool Function() complete,
) async {
  loggedOut.onLoginStateChanged.add(LoginState.loggedOut);
  await _pumpUntil(harness, complete);
}

/// The last logout waits for frames.
Future<void> _pumpUntil(
  _Harness harness,
  bool Function() done, {
  Duration frame = Duration.zero,
}) async {
  for (var i = 0; i < 100 && !done(); i++) {
    await harness.tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await harness.tester.pump(frame);
  }
}

/// The active account `a` and the one that replaces it, with the contacts
/// lookup stopped. A logout and a rolled-back login both hand over this way.
({_BootClient active, _BootClient next, _Harness harness}) _activeAndNext(
  WidgetTester tester,
) {
  final active = _BootClient('a', userID: '@a:s');
  final next = _BootClient('b', userID: '@b:s');
  return (
    active: active,
    next: next,
    harness: _handoverHarness(tester, [active, next]),
  );
}

/// Accounts with the contacts lookup stopped, the way a logout and a
/// rolled-back login both hand the active account over.
_Harness _handoverHarness(
  WidgetTester tester,
  List<Client> clients, {
  ReportFailure? report,
}) => _Harness(
  tester,
  clients,
  overrides: [
    phonebookResolverProvider.overrideWithValue(_NoopPhonebookResolver()),
    if (report != null) reportFailureProvider.overrideWithValue(report),
  ],
);

Future<({AccountSwitchCoordinator coordinator, _RecordingEffects effects})>
_recordedSwitch(_Harness harness) async {
  late _RecordingEffects effects;
  final coordinator = await harness.switchingWith(
    (matrix) => effects = _RecordingEffects(matrix),
    routed: true,
  );
  return (coordinator: coordinator, effects: effects);
}

void _expectActive(
  _Harness harness,
  Client next,
  _RecordingEffects effects,
  String name,
) {
  expect(harness.container.read(activeMatrixClientProvider), same(next));
  expect(harness.container.read(accountClientsProvider), [next]);
  expect(effects.applied, [name]);
}

/// A screen behind login: it watches the active client.
class _ClientReader extends ConsumerStatefulWidget {
  const _ClientReader({required this.onDispose});

  final VoidCallback onDispose;

  @override
  ConsumerState<_ClientReader> createState() => _ClientReaderState();
}

class _ClientReaderState extends ConsumerState<_ClientReader> {
  @override
  Widget build(BuildContext context) {
    ref.watch(matrixClientProvider);
    return const SizedBox();
  }

  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
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
    bool disposeContainer = true,
    bool tomFromGetIt = true,
  }) : container = ProviderContainer(
         retry: (_, _) => null,
         overrides: [
           if (tomFromGetIt) _tomFromGetIt,
           accountClientDataSourceProvider.overrideWithValue(
             FakeAccountClientDataSource(),
           ),
           bootClientsProvider.overrideWithValue(clients),
           bootAccountSnapshotProvider.overrideWithValue(snapshot),
           ...overrides,
         ],
       ) {
    if (disposeContainer) addTearDown(container.dispose);
  }

  final WidgetTester tester;
  final List<Client> clients;
  final ProviderContainer container;

  MatrixState get matrix => tester.state<MatrixState>(find.byType(Matrix));

  /// The post-frame `initMatrix` needs the whole app wiring, which these tests
  /// do not cover: the services it reads from GetIt are missing, and only
  /// those failures are dropped. Any other error, of [body] or of the boot,
  /// fails the test.
  Future<void> run(Future<void> Function() body) async {
    final done = Completer<void>();
    final unexpected = <Object>[];
    // On a macOS host `MatrixState` builds the macOS notifications port, and
    // the plugin reads the target platform, which `flutter test` sets to
    // Android: it is set to macOS, with the plugin channels answered.
    final onMacOS = Platform.isMacOS;
    if (onMacOS) {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      for (final name in _macosChannels) {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(MethodChannel(name), (_) async => true);
      }
    }
    runZonedGuarded(
      () async {
        try {
          await body();
          done.complete();
        } catch (e, s) {
          done.completeError(e, s);
        }
      },
      (e, s) {
        if (!_isMissingWiring(e)) unexpected.add(e);
      },
    );
    try {
      await done.future;
    } finally {
      if (onMacOS) {
        debugDefaultTargetPlatformOverride = null;
        for (final name in _macosChannels) {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(MethodChannel(name), null);
        }
      }
    }
    expect(unexpected, isEmpty, reason: 'errors outside of the app wiring');
  }

  /// [routed]: the app navigator and the translations are there, for the
  /// snack bars a logout shows.
  Future<void> mount({bool routed = false}) {
    if (routed) {
      TwakeApp.routerKey = GlobalKey<NavigatorState>();
      getIt.registerSingleton(ResponsiveUtils());
    }
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: routed ? TwakeApp.routerKey : null,
          localizationsDelegates: routed ? L10n.localizationsDelegates : null,
          supportedLocales: routed
              ? L10n.supportedLocales
              : const [Locale('en', 'US')],
          home: Matrix(
            child: routed ? const Scaffold(body: SizedBox()) : const SizedBox(),
          ),
        ),
      ),
    );
  }

  Future<void> unmount() async {
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const SizedBox()),
    );
    await tester.pump();
  }

  /// Mounts, lets the boot run, then makes [effects] the switch effects.
  Future<AccountSwitchCoordinator> switchingWith(
    AccountSwitchEffects Function(MatrixState matrix) effects, {
    bool routed = false,
  }) async {
    await mount(routed: routed);
    await settle();
    container
        .read(accountSwitchEffectsHolderProvider.notifier)
        .set(effects(matrix));
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
    : harness = _toMHarness(tester);

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

/// Accounts `a`, `b` and `c` with a ToM token. The login configuration
/// persister, which the fresh-install fallback saves through, can be built:
/// its federation repository is a fake, not the GetIt one.
_Harness _toMHarness(WidgetTester tester, {Uri? serverOfB}) => _Harness(
  tester,
  [
    _ToMClient('a', userID: '@a:s'),
    _ToMClient('b', userID: '@b:s', server: serverOfB),
    _ToMClient('c', userID: '@c:s'),
  ],
  overrides: [
    federationConfigurationsRepositoryProvider.overrideWithValue(
      _RecordingFederation(),
    ),
    phonebookResolverProvider.overrideWithValue(_NoopPhonebookResolver()),
  ],
);

/// A homeserver summary that announces a federation server.
HomeserverSummary _summaryWithFederation() => HomeserverSummary(
  discoveryInformation: DiscoveryInformation(
    mHomeserver: HomeserverInformation(baseUrl: Uri.parse('https://a')),
    additionalProperties: {
      'm.federated_identity_services': {
        'base_urls': ['https://fed.example'],
      },
    },
  ),
  versions: GetVersionsResponse(versions: []),
  loginFlows: [],
);

class _RecordingFederation extends Fake
    implements FederationConfigurationsRepository {
  final saved = <String>[];

  @override
  Future<void> saveFederationConfigurations(
    String userId,
    FederationConfigurations configurations,
  ) async => saved.add(userId);
}

class _UnusedTom extends Fake implements ToMConfigurationsRepository {}

/// A homeserver summary that announces the ToM server at [url].
HomeserverSummary _summaryWithToM(
  String url, {
  String homeserver = 'https://c',
}) => HomeserverSummary(
  discoveryInformation: DiscoveryInformation(
    mHomeserver: HomeserverInformation(baseUrl: Uri.parse(homeserver)),
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

class _CountingRemovals extends LogoutRemovals {
  int disposes = 0;
  int retryAlls = 0;

  @override
  Future<void> retryAll() {
    retryAlls++;
    return super.retryAll();
  }

  @override
  void dispose() {
    disposes++;
    super.dispose();
  }
}

class _CountingSubscriptions extends ClientSubscriptions {
  int cancelAlls = 0;

  @override
  Future<void> cancelAll() {
    cancelAlls++;
    return super.cancelAll();
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    getIt.registerSingleton<NetworkConnectionService>(
      _FakeNetworkConnectionService(),
    );
  });
  tearDown(getIt.reset);

  testWidgets('the account services are freed once, by the container', (
    tester,
  ) async {
    final logout = _CountingRemovals();
    final push = _CountingRemovals();
    final candidate = _CountingRemovals();
    final subscriptions = _CountingSubscriptions();
    final harness = _Harness(
      tester,
      [_BootClient('a', userID: '@a:s')],
      disposeContainer: false,
      overrides: [
        clientSubscriptionsProvider.overrideWith((ref) {
          ref.onDispose(() => unawaited(subscriptions.cancelAll()));
          return subscriptions;
        }),
        logoutRemovalsProvider.overrideWith((ref) {
          ref.onDispose(logout.dispose);
          return logout;
        }),
        pushRemovalsProvider.overrideWith((ref) {
          ref.onDispose(push.dispose);
          return push;
        }),
        candidateRemovalsProvider.overrideWith((ref) {
          ref.onDispose(candidate.dispose);
          return candidate;
        }),
      ],
    );

    await harness.run(() async {
      await harness.mount();
      await harness.unmount();
    });

    expect(subscriptions.cancelAlls, 0);
    expect(logout.disposes, 0);
    expect(push.disposes, 0);
    expect(candidate.disposes, 0);

    harness.container.dispose();

    expect(subscriptions.cancelAlls, 1);
    expect(logout.disposes, 1);
    expect(push.disposes, 1);
    expect(candidate.disposes, 1);
  });

  testWidgets('the set-up of a login uses the authentication server of the '
      'summary it is given, not the one the picker holds now', (tester) async {
    HomeserverSummary summaryWith(String issuer) => HomeserverSummary(
      discoveryInformation: DiscoveryInformation(
        mHomeserver: HomeserverInformation(
          baseUrl: Uri.parse('https://hs.example.com'),
        ),
        additionalProperties: {
          'm.authentication': {'issuer': issuer},
        },
      ),
      versions: GetVersionsResponse(versions: ['r1.6.0']),
      loginFlows: [],
    );
    final client = _BootClient('a', userID: '@a:s');
    final harness = _Harness(tester, [client]);

    await harness.run(() async {
      await harness.mount();
      harness.container
          .read(loginHomeserverSummaryProvider.notifier)
          .set(summaryWith('https://auth.picked'));
      try {
        await harness.matrix.setUpToMServicesInLogin(
          client,
          summaryWith('https://auth.of-the-login'),
        );
      } catch (_) {
        // The rest of the set-up needs the app wiring that is missing here.
      }
    });

    expect(harness.matrix.authUrl, 'https://auth.of-the-login');
  });

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
    final effects = harness.container.read(accountSwitchEffectsHolderProvider);
    expect(effects, isNull);

    await harness.run(() async {
      await harness.mount();
      expect(
        harness.container.read(accountSwitchEffectsHolderProvider),
        same(harness.matrix),
      );
      expect(harness.container.read(pushRemovalsControllerProvider), isNotNull);

      await harness.unmount();
    });

    expect(harness.container.read(accountSwitchEffectsHolderProvider), isNull);
    expect(harness.container.read(pushRemovalsControllerProvider), isNull);
  });

  testWidgets('a sync of the account left behind does not look up its '
      'support chat any more', (tester) async {
    final left = _BootClient('a', userID: '@a:s');
    final active = _BootClient('b', userID: '@b:s');
    final supportChat = _RecordingSupportChat();
    getIt.registerSingleton<CreateSupportChatInteractor>(supportChat);
    final harness = _Harness(tester, [left, active]);

    String? roomId;
    await harness.run(() async {
      await harness.mount();
      harness.matrix
        ..createSupportChat(left)
        ..createSupportChat(active);
      await tester.runAsync(() async {
        left.onSync.add(SyncUpdate(nextBatch: 'a1'));
        await Future<void>.delayed(Duration.zero);
        active.onSync.add(SyncUpdate(nextBatch: 'b1'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      // The lookup listens in the test zone: its events need a pump.
      await tester.pump();
      roomId = harness.matrix.supportChatRoomId;
      await harness.unmount();
    });

    expect(supportChat.lookedUp, ['b']);
    expect(roomId, '!support-b');
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

  testWidgets('registering the subscriptions listens to the login state '
      'before its first await', (tester) async {
    final client = _BootClient('a', userID: '@a:s');
    final harness = _Harness(tester, [client]);

    await harness.run(() async {
      await harness.mount();
      final host = harness.matrix.loginHost;
      await tester.runAsync(
        () => host.cancelSubscriptions(const AccountId('a')),
      );
      client.onLoginStateChanged.listened = false;

      final registering = host.registerSubscriptions(const AccountId('a'));

      // onLoginStateChanged does not replay: a login state sent before the
      // listen would be lost.
      expect(client.onLoginStateChanged.listened, isTrue);
      unawaited(registering);
      await harness.settle();
    });
  });

  testWidgets('a ToM configuration without identity server does not keep the '
      'one of the account before', (tester) async {
    _registerToM(_FakeToMConfigurationsRepository({}));
    final identity = getIt.get<DynamicUrlInterceptors>(
      instanceName: NetworkDI.identityServerUrlInterceptorName,
    );
    final harness = _Harness(
      tester,
      [_ToMClient('a', userID: '@a:s')],
      overrides: [
        phonebookResolverProvider.overrideWithValue(_NoopPhonebookResolver()),
      ],
    );

    await harness.run(() async {
      await harness.mount();
      await harness.settle();
      identity.changeBaseUrl('https://id.a');
      harness.matrix.setUpToMServices(
        ToMServerInformation(baseUrl: Uri.parse('https://tom.b')),
        null,
      );
    });

    expect(identity.baseUrl, isNull);
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
    final identity = getIt.get<DynamicUrlInterceptors>(
      instanceName: NetworkDI.identityServerUrlInterceptorName,
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
      identity.changeBaseUrl('https://id.a');
      authorization.accessToken = null;
      harness.container
          .read(accountSwitchEffectsHolderProvider.notifier)
          .set(_ToMOnlyEffects(harness.matrix));

      final result = await tester.runAsync(
        () => harness.matrix.setActiveClient(target),
      );
      expect(result, SetActiveClientState.success);
    });

    // The target has no configuration: nothing of account `a` stays bound.
    expect(tomServer.baseUrl, isNull);
    expect(identity.baseUrl, isNull);
    expect(authorization.accessToken, 'token-b');
  });

  testWidgets('a switch does not write the access token to the logs', (
    tester,
  ) async {
    final left = _ToMClient('a', userID: '@a:s');
    final target = _ToMClient('b', userID: '@b:s');
    final authorization = AuthorizationInterceptor();
    _registerToM(
      _FakeToMConfigurationsRepository({}),
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
      harness.container
          .read(accountSwitchEffectsHolderProvider.notifier)
          .set(_ToMOnlyEffects(harness.matrix));
      Logs().outputEvents.clear();

      await tester.runAsync(() => harness.matrix.setActiveClient(target));
    });

    expect(authorization.accessToken, 'token-b');
    expect(
      Logs().outputEvents.map((event) => event.title),
      everyElement(isNot(contains('token-b'))),
    );
  });

  group('a switch to an account whose homeserver cannot be reached', () {
    // Nothing can be fetched in the harness: `checkHomeserver` and the
    // well-known of the fake clients both fail, as they do offline.
    final serverA = Uri.parse('https://a.example');
    final serverB = Uri.parse('https://b.example');

    _Harness harnessOf(WidgetTester tester) => _Harness(
      tester,
      [
        _ToMClient('a', userID: '@a:s', server: serverA),
        _ToMClient('b', userID: '@b:s', server: serverB),
      ],
      overrides: [
        federationConfigurationsRepositoryProvider.overrideWithValue(
          _RecordingFederation(),
        ),
        phonebookResolverProvider.overrideWithValue(_NoopPhonebookResolver()),
      ],
    );

    testWidgets('does not take the ToM server of the account it leaves', (
      tester,
    ) async {
      final repository = _FakeToMConfigurationsRepository({});
      final tomServer = _registerToM(repository);
      final harness = harnessOf(tester);

      await harness.run(() async {
        final coordinator = await harness.switchingWith(_ToMOnlyEffects.new);
        tomServer.changeBaseUrl(null);
        harness.matrix.loginHomeserverSummary = _summaryWithToM(
          'https://tom.a',
          homeserver: serverA.toString(),
        );
        await tester.runAsync(() => coordinator.apply(harness.clients[1]));
      });

      expect(repository.saved, isEmpty);
      expect(tomServer.baseUrl, isNull);
      expect(harness.matrix.loginHomeserverSummary, isNull);
    });

    testWidgets('publishes the cached discovery before the user info', (
      tester,
    ) async {
      final harness = _Harness(
        tester,
        [
          _ToMClient('a', userID: '@a:s', server: serverA),
          _CachedDiscoveryClient(
            'b',
            userID: '@b:s',
            server: serverB,
            wellKnown: {
              'm.homeserver': {'base_url': serverB.toString()},
              RtcFocus.rtcFociKey: [
                {'type': 'livekit', 'livekit_base_url': 'https://meet.b'},
              ],
            },
          ),
        ],
        overrides: [
          federationConfigurationsRepositoryProvider.overrideWithValue(
            _RecordingFederation(),
          ),
          phonebookResolverProvider.overrideWithValue(_NoopPhonebookResolver()),
        ],
      );
      late _DiscoveryEffects effects;

      await harness.run(() async {
        final coordinator = await harness.switchingWith(
          (matrix) => effects = _DiscoveryEffects(matrix),
        );
        await tester.runAsync(() => coordinator.apply(harness.clients[1]));
      });

      expect(effects.videoCallUrlAtUserInfo, 'https://meet.b');
    });

    testWidgets('keeps the summary held for its own homeserver', (
      tester,
    ) async {
      final repository = _FakeToMConfigurationsRepository({});
      final tomServer = _registerToM(repository);
      final harness = harnessOf(tester);

      await harness.run(() async {
        final coordinator = await harness.switchingWith(_ToMOnlyEffects.new);
        tomServer.changeBaseUrl(null);
        harness.matrix.loginHomeserverSummary = _summaryWithToM(
          'https://tom.b',
          homeserver: serverB.toString(),
        );
        await tester.runAsync(() => coordinator.apply(harness.clients[1]));
      });

      expect(repository.saved.keys, ['@b:s']);
      expect(tomServer.baseUrl, 'https://tom.b');
    });
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

  testWidgets('a switch still current stores the ToM configuration it '
      'discovered', (tester) async {
    // The positive case of the test above: there, an empty `saved` means the
    // stale run was stopped, not that saving cannot work in this harness.
    final repository = _FakeToMConfigurationsRepository({});
    _registerToM(repository);
    // B has the homeserver the held summary describes, so the discovery of
    // the switch reuses it; without one the summary would not be B's.
    final harness = _toMHarness(tester, serverOfB: Uri.parse('https://c'));

    await harness.run(() async {
      final coordinator = await harness.switchingWith(_ToMOnlyEffects.new);
      harness.matrix.loginHomeserverSummary = _summaryWithToM('https://tom.c');
      await tester.runAsync(() => coordinator.apply(harness.clients[1]));
    });

    expect(repository.saved.keys, ['@b:s']);
    expect(
      repository.saved['@b:s']!.tomServerInformation.baseUrl,
      Uri.parse('https://tom.c'),
    );
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

  group('a switch that is overtaken stops writing the shared state', () {
    // The switch to `stale` is held and the one to `c` overtakes it; `stale`
    // goes on when the hold opens and must leave what `c` wrote.
    Future<void> overtakeWith(
      _Harness harness,
      AccountSwitchEffects Function(MatrixState matrix) effects,
      _Hold hold, {
      int stale = 1,
      void Function()? afterBoot,
    }) async {
      final coordinator = await harness.switchingWith(effects);
      afterBoot?.call();
      await harness.tester.runAsync(() async {
        hold.armed = true;
        final older = coordinator.apply(harness.clients[stale]);
        await hold.reached.future;
        await coordinator.apply(harness.clients[2]);
        hold.gate.complete();
        await older;
      });
    }

    testWidgets('the homeserver summary of the account that overtook it '
        'stays', (tester) async {
      final hold = _Hold();
      // `a` is the active account, so only the token tells its late result
      // from the one of the account that is wanted.
      final harness = _Harness(tester, [
        _WellKnownClient('a', userID: '@a:s', hold: hold),
        _WellKnownClient('b', userID: '@b:s'),
        _WellKnownClient('c', userID: '@c:s'),
      ]);

      await harness.run(() async {
        await overtakeWith(
          harness,
          _HomeserverOnlyEffects.new,
          hold,
          stale: 0,
          // After the boot, which would otherwise fetch the well-known of the
          // active account in the fake-async zone.
          afterBoot: () => harness.clients.cast<_WellKnownClient>().forEach(
            (client) => client
              ..announce()
              ..useNetwork(),
          ),
        );

        expect(
          harness
              .matrix
              .loginHomeserverSummary
              ?.discoveryInformation
              ?.mHomeserver
              .baseUrl,
          _announcedBy('c'),
        );
      });
    });

    testWidgets('the account that overtook it stays the persisted one', (
      tester,
    ) async {
      final hold = _Hold();
      final harness = _Harness(tester, [
        _BootClient('a', userID: '@a:s'),
        _BootClient('b', userID: '@b:s'),
        _BootClient('c', userID: '@c:s'),
      ]);

      await harness.run(() async {
        await overtakeWith(
          harness,
          (matrix) => _PersistingEffects(matrix, hold),
          hold,
        );

        final persisted = await tester.runAsync(
          () => harness.container
              .read(accountRepositoryProvider)
              .persistedActiveUserId(),
        );
        expect(persisted, '@c:s');
      });
    });

    testWidgets('the ToM configuration read first by the switch that was '
        'overtaken is not applied', (tester) async {
      final repository = _GatedToMConfigurationsRepository(
        {'@b:s': _toM('https://tom.b'), '@c:s': _toM('https://tom.c')},
        gatedId: '@b:s',
        heldRead: 1,
        lateValue: _toM('https://tom.b'),
      );
      final tomServer = _registerToM(repository);

      final applied = await _ToMOvertaking(tester, repository.hold).run();

      expect(applied, isFalse);
      expect(tomServer.baseUrl, 'https://tom.c');
    });
  });

  group('a switch request that is overtaken', () {
    /// `a` is active; the switch to `b` is held at its ToM read and the one to
    /// `c` overtakes it. Returns what [first] answered for `b`.
    Future<T?> overtaken<T>(
      WidgetTester tester,
      Future<T> Function(_Harness harness, Client b) first,
    ) async {
      final repository = _GatedToMConfigurationsRepository(
        {'@b:s': _toM('https://tom.b'), '@c:s': _toM('https://tom.c')},
        gatedId: '@b:s',
        heldRead: 1,
      );
      _registerToM(repository);
      final harness = _toMHarness(tester);
      T? answer;
      await harness.run(() async {
        await harness.switchingWith(_ToMOnlyEffects.new);
        await tester.runAsync(() async {
          repository.hold.armed = true;
          final pending = first(harness, harness.clients[1]);
          await repository.hold.reached.future;
          expect(
            await harness.matrix.setActiveClient(harness.clients[2]),
            SetActiveClientState.success,
          );
          repository.hold.gate.complete();
          answer = await pending;
        });
      });
      return answer;
    }

    testWidgets('is answered as superseded, not as unavailable', (
      tester,
    ) async {
      final answer = await overtaken(
        tester,
        (harness, b) => harness.matrix.setActiveClient(b),
      );

      expect(answer, SetActiveClientState.superseded);
    });

    testWidgets('does not undo the login that asked for it', (tester) async {
      final answer = await overtaken(
        tester,
        (harness, b) => harness.matrix.loginHost.switchTo(b),
      );

      expect(answer, isTrue);
    });
  });

  testWidgets('a boot read that a switch overtakes does not apply the '
      'configuration of the account it left', (tester) async {
    final repository = _GatedToMConfigurationsRepository(
      {'@b:s': _toM('https://tom.b')},
      gatedId: '@a:s',
      lateValue: _toM('https://tom.a'),
      heldRead: 1,
    );
    final tomServer = _registerToM(repository);
    final harness = _toMHarness(tester);

    await harness.run(() async {
      repository.hold.armed = true;
      await harness.mount();
      await harness.settle();
      harness.container
          .read(accountSwitchEffectsHolderProvider.notifier)
          .set(_ToMOnlyEffects(harness.matrix));
      await tester.runAsync(() async {
        await repository.hold.reached.future;
        await harness.matrix.setActiveClient(harness.clients[1]);
        repository.hold.gate.complete();
        await Future<void>.delayed(Duration.zero);
      });
    });

    expect(tomServer.baseUrl, 'https://tom.b');
  });

  testWidgets('an account is not settled while a switch away from it runs', (
    tester,
  ) async {
    final repository = _GatedToMConfigurationsRepository(
      {'@b:s': _toM('https://tom.b')},
      gatedId: '@b:s',
      heldRead: 1,
    );
    _registerToM(repository);
    final harness = _toMHarness(tester);
    final origin = harness.clients[0];
    final target = harness.clients[1];
    late List<bool> whileSwitching;

    await harness.run(() async {
      await harness.switchingWith(_ToMOnlyEffects.new);
      expect(harness.matrix.isSettledOn(origin), isTrue);
      await tester.runAsync(() async {
        repository.hold.armed = true;
        final switching = harness.matrix.setActiveClient(target);
        await repository.hold.reached.future;
        whileSwitching = [
          harness.matrix.isSettledOn(origin),
          harness.matrix.isSettledOn(target),
        ];
        repository.hold.gate.complete();
        await switching;
      });
      expect(harness.matrix.isSettledOn(target), isTrue);
      expect(harness.matrix.isSettledOn(origin), isFalse);
    });

    expect(whileSwitching, [false, false]);
  });

  group('the logout hand-over of MatrixState', () {
    testWidgets('logging the active account out activates the next one and '
        'applies its effects', (tester) async {
      final hand = _activeAndNext(tester);

      late _RecordingEffects effects;
      await hand.harness.run(() async {
        final recorded = await _recordedSwitch(hand.harness);
        effects = recorded.effects;
        expect(
          hand.harness.container.read(activeMatrixClientProvider),
          hand.active,
        );

        await _logoutAndWait(
          hand.harness,
          hand.active,
          () => recorded.coordinator.isAppliedTo(hand.next),
        );
        await hand.harness.unmount();
      });

      // `_removeLoggedOutAccount` removed `a`, then `_activateAfterLogout`
      // applied the effects of the account that took its place.
      _expectActive(hand.harness, hand.next, effects, 'b');
    });

    testWidgets('logging the last account out goes to the logged-out flow and '
        'applies no effects', (tester) async {
      final last = _BootClient('a', userID: '@a:s');
      final harness = _handoverHarness(tester, [last]);

      late _RecordingEffects effects;
      late AccountSwitchCoordinator coordinator;
      await harness.run(() async {
        final recorded = await _recordedSwitch(harness);
        coordinator = recorded.coordinator;
        effects = recorded.effects;

        await _logoutAndWait(
          harness,
          last,
          () => harness.container.read(accountsProvider) is! Active,
        );
      });

      expect(harness.container.read(accountsProvider), isA<LastLoggedOut>());
      expect(harness.container.read(activeMatrixClientProvider), isNull);
      expect(coordinator.isAppliedTo(last), isFalse);
      expect(effects.applied, isEmpty);
    });
    testWidgets('the last logout unmounts the screens reading the client '
        'before the accounts drop it', (tester) async {
      final last = _BootClient('a', userID: '@a:s');
      final tom = _CountingToMDatabase();
      getIt.registerSingleton<HiveCollectionToMDatabase>(tom);
      final harness = _handoverHarness(tester, [last]);
      final events = <String>[];
      final locationsWhenDropped = <String>[];
      final entering = MaterialPageRoute<void>(
        builder: (_) => const SizedBox(),
      );
      late AccountsState whileEntering;

      await harness.run(() async {
        await _recordedSwitch(harness);
        harness.container.listen(accountsProvider, (_, next) {
          if (next is! Active) {
            events.add('client dropped');
            locationsWhenDropped.add(
              TwakeApp.router.routeInformationProvider.value.uri.path,
            );
          }
        });
        final navigator = TwakeApp.routerKey.currentState!;
        unawaited(
          navigator.push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  _ClientReader(onDispose: () => events.add('reader disposed')),
            ),
          ),
        );
        await tester.pumpAndSettle();
        // The harness does not render `TwakeApp.router`: replace the screens
        // the way its navigation would.
        final location = TwakeApp.router.routeInformationProvider;
        void replaceScreens() {
          if (location.value.uri.path.startsWith('/home')) {
            unawaited(navigator.pushAndRemoveUntil(entering, (r) => r.isFirst));
          }
        }

        location.addListener(replaceScreens);
        addTearDown(() => location.removeListener(replaceScreens));

        last.onLoginStateChanged.add(LoginState.loggedOut);
        await _pumpUntil(
          harness,
          () => TwakeApp.router.routeInformationProvider.value.uri.path
              .startsWith('/home'),
        );
        for (var i = 0; i < 5; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await tester.pump();
        }
        whileEntering = harness.container.read(accountsProvider);
        await _pumpUntil(
          harness,
          () => harness.container.read(accountsProvider) is! Active,
          frame: const Duration(milliseconds: 100),
        );
        await _pumpUntil(harness, () => tom.clears > 0);
        await _pumpUntil(harness, () => false);
      });

      expect(tom.clears, 1);
      expect(whileEntering, isA<Active>());
      expect(entering.animation!.isCompleted, isTrue);
      expect(events, ['reader disposed', 'client dropped']);
      expect(locationsWhenDropped, [startsWith('/home')]);
      expect(harness.container.read(accountsProvider), isA<LastLoggedOut>());
    });

    for (final (lifecycle, reported) in [
      (AppLifecycleState.resumed, true),
      (AppLifecycleState.paused, false),
    ]) {
      testWidgets('the last logout stops waiting for the screens behind login '
          'after a while (${lifecycle.name})', (tester) async {
        final last = _BootClient('a', userID: '@a:s');
        final reports = <String>[];
        final harness = _handoverHarness(tester, [
          last,
        ], report: (error, stackTrace, what) => reports.add(what));
        final endless = PageRouteBuilder<void>(
          transitionDuration: const Duration(hours: 1),
          pageBuilder: (_, _, _) => const SizedBox(),
        );

        await harness.run(() async {
          await _recordedSwitch(harness);
          unawaited(TwakeApp.routerKey.currentState!.push(endless));
          tester.binding.handleAppLifecycleStateChanged(lifecycle);
          addTearDown(
            () => tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.resumed,
            ),
          );

          last.onLoginStateChanged.add(LoginState.loggedOut);
          await _pumpUntil(
            harness,
            () => TwakeApp.router.routeInformationProvider.value.uri.path
                .startsWith('/home'),
          );
          await tester.pump(const Duration(milliseconds: 1900));
          expect(harness.container.read(accountsProvider), isA<Active>());
          await tester.pump(const Duration(milliseconds: 200));
          await _pumpUntil(
            harness,
            () => harness.container.read(accountsProvider) is! Active,
          );
        });

        expect(endless.animation!.isCompleted, isFalse);
        expect(harness.container.read(accountsProvider), isA<LastLoggedOut>());
        expect(
          reports.contains(
            'MatrixState: screens behind login still mounted at the last '
            'logout',
          ),
          reported,
        );
      });
    }
  });

  testWidgets('a login during the wait of the last logout removes the account '
      'that logged out and keeps the ToM data', (tester) async {
    final last = _BootClient('a', userID: '@a:s');
    final tom = _CountingToMDatabase();
    getIt.registerSingleton<HiveCollectionToMDatabase>(tom);
    final harness = _handoverHarness(tester, [last]);
    final endless = PageRouteBuilder<void>(
      transitionDuration: const Duration(hours: 1),
      pageBuilder: (_, _, _) => const SizedBox(),
    );

    await harness.run(() async {
      await _recordedSwitch(harness);
      unawaited(TwakeApp.routerKey.currentState!.push(endless));

      last.onLoginStateChanged.add(LoginState.loggedOut);
      await _pumpUntil(
        harness,
        () => TwakeApp.router.routeInformationProvider.value.uri.path
            .startsWith('/home'),
      );
      harness.container
          .read(accountClientRegistryProvider)
          .add(_BootClient('b', userID: '@b:s'));
      await harness.tester.runAsync(
        () => harness.container
            .read(accountsProvider.notifier)
            .addAccount(const AccountId('b')),
      );
      await _pumpUntil(
        harness,
        () => false,
        frame: const Duration(milliseconds: 500),
      );
    });

    final accounts = harness.container.read(accountsProvider);
    expect(accounts, isA<Active>());
    expect(accounts.accounts.map((a) => a.id), ['b']);
    expect((accounts as Active).activeId, 'b');
    expect(tom.clears, 0);
  });

  group('the login host of MatrixState', () {
    testWidgets('removing an account of a rolled-back login keeps the screen', (
      tester,
    ) async {
      final hand = _activeAndNext(tester);

      late _RecordingEffects effects;
      late Uri location;
      await hand.harness.run(() async {
        final recorded = await _recordedSwitch(hand.harness);
        effects = recorded.effects;
        location = TwakeApp.router.routeInformationProvider.value.uri;
        // The removal awaits the store. Awaiting it inside `runAsync` pauses
        // the test binding, so the store future never runs. The logout tests
        // start the work in the test zone and only poll from `runAsync`.
        unawaited(
          hand.harness.matrix.loginHost.removeAccount(const AccountId('a')),
        );
        await hand.harness.settle();
        await tester.runAsync(
          () => _until(() => recorded.coordinator.isAppliedTo(hand.next)),
        );
        await hand.harness.unmount();
      });

      // The replacement is active, and the login screen is not sent away:
      // `removeAccount` asks for the hand-over with `navigate: false`.
      _expectActive(hand.harness, hand.next, effects, 'b');
      expect(TwakeApp.router.routeInformationProvider.value.uri, location);
    });

    testWidgets('federation set-up goes through the login configuration '
        'persister', (tester) async {
      final client = _BootClient('a', userID: '@a:s');
      final federation = _RecordingFederation();
      final harness = _Harness(
        tester,
        [client],
        tomFromGetIt: false,
        overrides: [
          tomConfigurationsRepositoryProvider.overrideWithValue(_UnusedTom()),
          federationConfigurationsRepositoryProvider.overrideWithValue(
            federation,
          ),
        ],
      );

      await harness.run(() async {
        await harness.mount();
        harness.matrix.loginHomeserverSummary = _summaryWithFederation();
        await harness.matrix.loginHost.setUpFederation(
          client,
          harness.matrix.loginHomeserverSummary,
        );
      });

      expect(federation.saved, ['@a:s']);
    });

    testWidgets('a login without its own summary saves no federation of the '
        'active account', (tester) async {
      final client = _BootClient('a', userID: '@a:s');
      final federation = _RecordingFederation();
      final harness = _Harness(
        tester,
        [client],
        tomFromGetIt: false,
        overrides: [
          tomConfigurationsRepositoryProvider.overrideWithValue(_UnusedTom()),
          federationConfigurationsRepositoryProvider.overrideWithValue(
            federation,
          ),
        ],
      );

      await harness.run(() async {
        await harness.mount();
        harness.matrix.loginHomeserverSummary = _summaryWithFederation();
        await harness.matrix.loginHost.setUpFederation(client, null);
      });

      expect(federation.saved, isEmpty);
    });

    testWidgets('a login without its own summary does not take the auth '
        'server of the active account', (tester) async {
      final client = _BootClient('a', userID: '@a:s');
      final harness = _Harness(tester, [client]);

      await harness.run(() async {
        await harness.mount();
        harness.matrix.loginHomeserverSummary = HomeserverSummary(
          discoveryInformation: DiscoveryInformation(
            mHomeserver: HomeserverInformation(
              baseUrl: Uri.parse('https://hs.example.com'),
            ),
            additionalProperties: {
              'm.authentication': {'issuer': 'https://auth.active'},
            },
          ),
          versions: GetVersionsResponse(versions: ['r1.6.0']),
          loginFlows: [],
        );
        try {
          await harness.matrix.setUpToMServicesInLogin(client);
        } catch (_) {
          // The rest of the set-up needs the app wiring that is missing here.
        }
      });

      expect(harness.matrix.authUrl, isNot('https://auth.active'));
    });

    testWidgets('retrying the pending removals retries the logout removals '
        'and the candidate discards', (tester) async {
      final logout = _CountingRemovals();
      final candidate = _CountingRemovals();
      final harness = _Harness(
        tester,
        [_BootClient('a', userID: '@a:s')],
        overrides: [
          logoutRemovalsProvider.overrideWith((ref) {
            ref.onDispose(logout.dispose);
            return logout;
          }),
          candidateRemovalsProvider.overrideWith((ref) {
            ref.onDispose(candidate.dispose);
            return candidate;
          }),
        ],
      );

      await harness.run(() async {
        await harness.mount();
        await harness.matrix.loginHost.retryPendingRemovals();
      });

      expect(logout.retryAlls, 1);
      expect(candidate.retryAlls, 1);
    });

    testWidgets('a login session that outlives the widget still reads the '
        'accounts', (tester) async {
      final harness = _Harness(tester, [_BootClient('a', userID: '@a:s')]);
      late LoginHost host;

      await harness.run(() async {
        await harness.mount();
        host = harness.matrix.loginHost;
        await harness.unmount();
      });

      expect(host.isStored(const AccountId('a')), isTrue);
      expect(host.isLoggedIn(const AccountId('a')), isTrue);
    });

    testWidgets('a last logout the accounts refuse reaches the caller', (
      tester,
    ) async {
      final harness = _Harness(tester, [_BootClient('a', userID: '@a:s')]);

      await harness.run(() async {
        await harness.mount();
        final host = harness.matrix.loginHost;
        await host.logoutLast();
        // The state is now `LastLoggedOut`: a second one is refused, and the
        // refusal has to come back to the session that asked, not be lost.
        await expectLater(
          host.logoutLast(),
          throwsA(isA<InvalidAccountTransitionException>()),
        );
      });
    });

    // A session step that fails is caught by the session, but what it does in
    // its `catch` (report) and the arguments it builds before its `try` (the
    // active client) must not need the widget.
    testWidgets('after the widget is gone the host still answers what a '
        'session asks outside of a try', (tester) async {
      final reports = <String>[];
      final client = _BootClient('a', userID: '@a:s');
      final harness = _Harness(
        tester,
        [client],
        overrides: [
          reportFailureProvider.overrideWithValue(
            (error, stackTrace, what) => reports.add(what),
          ),
        ],
      );
      late LoginHost host;

      await harness.run(() async {
        await harness.mount();
        host = harness.matrix.loginHost;
        await harness.unmount();
      });

      expect(host.activeClient, same(client));
      expect(host.activeClientName, 'a');
      expect(host.clientByName(const AccountId('a')), same(client));
      host.report(StateError('x'), StackTrace.empty, 'step');
      // The boot of the widget may report its own failures too, and when it
      // does depends on timing: only the report of the host matters here.
      expect(reports, contains('MatrixState: login: step'));
      host.emit(
        ClientLoginStateEvent(
          client: client,
          loginState: LoginState.loggedOut,
          multipleAccountLoginType: MultipleAccountLoginType.loginFailed,
          error: StateError('x'),
        ),
      );
    });
  });

  // Review of #3732 (jbrnzl): the client keeps the rooms the user left
  // (sync with includeLeave), with their unread counts; the room list hides
  // them, so must the Dock.
  testWidgets('the Dock badge leaves out the rooms the user is no longer in', (
    tester,
  ) async {
    final client = _RoomsBootClient('a', userID: '@a:s');
    client.rooms = [
      Room(id: '!joined:s', client: client, notificationCount: 2),
      Room(
        id: '!left:s',
        client: client,
        membership: Membership.leave,
        notificationCount: 3,
      ),
      Room(
        id: '!banned:s',
        client: client,
        membership: Membership.ban,
        notificationCount: 4,
      ),
    ];
    final shown = <int>[];
    FlutterAppBadger.setMocks(
      updateBadgeCount: (count) async => shown.add(count),
      removeBadge: () async => shown.add(0),
    );
    addTearDown(FlutterAppBadger.clearMocks);
    final harness = _Harness(tester, [client]);

    await harness.run(() async {
      await harness.mount();
      await harness.settle();
      client.onSync.add(SyncUpdate(nextBatch: 'next'));
      await harness.settle();
    });

    expect(shown, isNotEmpty, reason: 'the Dock badge was never set');
    expect(shown.last, 2);
  }, skip: !Platform.isMacOS);
}
