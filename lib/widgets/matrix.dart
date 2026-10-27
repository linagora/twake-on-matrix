import 'dart:async';
import 'dart:io';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/config/localizations/localization_service.dart';
import 'package:twake_chat/data/model/federation_server/federation_configuration.dart';
import 'package:twake_chat/data/model/federation_server/federation_server_information.dart';
import 'package:twake_chat/domain/app_state/room/create_support_chat_state.dart';
import 'package:twake_chat/domain/exception/federation_configuration_not_found.dart';
import 'package:twake_chat/domain/model/homeserver_summary.dart';
import 'package:twake_chat/domain/repository/federation_configurations_repository.dart';
import 'package:twake_chat/domain/repository/user_info/user_info_repository.dart';
import 'package:twake_chat/domain/usecase/room/create_support_chat_interactor.dart';
import 'package:twake_chat/domain/matrix_events/event_type_rules.dart';
import 'package:twake_chat/event/twake_event_types.dart';
import 'package:twake_chat/pages/chat/events/audio_message/audio_player_widget.dart';
import 'package:twake_chat/presentation/mixins/connectivity_mixin.dart';
import 'package:twake_chat/presentation/mixins/init_config_mixin.dart';
import 'package:twake_chat/presentation/model/client_login_state_event.dart';
import 'package:twake_chat/widgets/layouts/agruments/logout_body_args.dart';
import 'package:flutter_emoji_mart/flutter_emoji_mart.dart';
import 'package:just_audio/just_audio.dart';
import 'package:linagora_design_flutter/cozy_config_manager/cozy_config_manager.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:universal_html/html.dart' as html hide File;

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:collection/collection.dart';
import 'package:desktop_notifications/desktop_notifications.dart';
import 'package:twake_chat/data/hive/hive_collection_tom_database.dart';
import 'package:twake_chat/data/network/interceptor/authorization_interceptor.dart';
import 'package:twake_chat/data/network/interceptor/dynamic_url_interceptor.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/di/global/network_di.dart';
import 'package:twake_chat/domain/model/extensions/homeserver_summary_extensions.dart';
import 'package:twake_chat/domain/model/tom_configurations.dart';
import 'package:twake_chat/domain/model/tom_server_information.dart';
import 'package:twake_chat/domain/repository/tom_configurations_repository.dart';
import 'package:twake_chat/pages/chat_list/receive_sharing_intent_mixin.dart';
import 'package:twake_chat/domain/account/entities/account.dart';
import 'package:twake_chat/domain/account/entities/account_id.dart';
import 'package:twake_chat/domain/account/entities/accounts_state.dart';
import 'package:twake_chat/domain/account/exceptions/account_exception.dart';
import 'package:twake_chat/pages/contacts_tab/providers/contacts_providers.dart';
import 'package:twake_chat/providers/account_usecase_providers.dart';
import 'package:twake_chat/providers/account_repository_provider.dart';
import 'package:twake_chat/providers/account_switch_coordinator.dart';
import 'package:twake_chat/providers/account_switch_effects_provider.dart';
import 'package:twake_chat/providers/accounts_provider.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/providers/account_services_providers.dart';
import 'package:twake_chat/data/account/client_subscriptions.dart';
import 'package:twake_chat/providers/login_candidate_provider.dart';
import 'package:twake_chat/providers/logout_removal_plan.dart';
import 'package:twake_chat/providers/push_removals_controller.dart';
import 'package:twake_chat/data/account/logout_removals.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';
import 'package:twake_chat/utils/localized_exception_extension.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/client_well_known_extension.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';
import 'package:twake_chat/utils/uia_request_manager.dart';
import 'package:twake_chat/utils/url_launcher.dart';
import 'package:twake_chat/widgets/set_active_client_state.dart';
import 'package:twake_chat/widgets/twake_app.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_app_lock/flutter_app_lock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ConsumerState, ConsumerStatefulWidget;
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:matrix/encryption.dart';
import 'package:matrix/matrix.dart';

// ignore: implementation_imports
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;

import '../config/app_config.dart';
import '../config/setting_keys.dart';
import '../pages/key_verification/key_verification_dialog.dart';
import '../utils/background_push.dart';
import '../utils/web_push/web_push.dart';
import '../utils/famedlysdk_store.dart';
import 'local_notifications_extension.dart';

class Matrix extends ConsumerStatefulWidget {
  final Widget? child;

  final List<Client> clients;

  final Map<String, String>? queryParameters;

  const Matrix({
    this.child,
    required this.clients,
    this.queryParameters,
    super.key,
  });

  @override
  MatrixState createState() => MatrixState();

  /// Returns the (nearest) Client instance of your application.
  static MatrixState of(BuildContext context) =>
      Provider.of<MatrixState>(context, listen: false);

  static MatrixState read(BuildContext context) => context.read<MatrixState>();
}

class MatrixState extends ConsumerState<Matrix>
    with
        WidgetsBindingObserver,
        ReceiveSharingIntentMixin,
        InitConfigMixin,
        ConnectivityMixin
    implements AccountSwitchEffects {
  AudioPlayer audioPlayer = AudioPlayer();
  final ValueNotifier<Event?> voiceMessageEvent = ValueNotifier(null);

  final ValueNotifier<AudioPlayerStatus> currentAudioStatus = ValueNotifier(
    AudioPlayerStatus.notDownloaded,
  );

  StreamSubscription<PlayerState>? _audioPlayerStateSubscription;

  late final AccountSwitchCoordinator _switchCoordinator;
  late final AccountSwitchEffectsHolder _switchEffects;
  Store store = Store();
  // TODO: [transitional] migrate call sites to loginHomeserverSummaryProvider and remove this getter/setter.
  HomeserverSummary? get loginHomeserverSummary =>
      ref.read(loginHomeserverSummaryProvider);

  set loginHomeserverSummary(HomeserverSummary? summary) =>
      ref.read(loginHomeserverSummaryProvider.notifier).set(summary);
  String? _authUrl;
  XFile? loginAvatar;
  String? loginUsername;
  String? loginType;
  bool? loginRegistrationSupported;
  late EmojiData emojiData;

  bool waitForFirstSync = false;

  ValueNotifier<bool> showQrCodeDownload = ValueNotifier(false);

  ValueNotifier<bool> showToMBootstrap = ValueNotifier(false);

  bool get twakeSupported {
    final tomServerUrlInterceptor = getIt.get<DynamicUrlInterceptors>(
      instanceName: NetworkDI.tomServerUrlInterceptorName,
    );
    return tomServerUrlInterceptor.baseUrl != null;
  }

  BackgroundPush? backgroundPush;

  bool get isValidActiveClient =>
      _switchCoordinator.hasApplied &&
      ref.read(activeMatrixClientProvider) != null;

  /// Every account the app lists (the former `widget.clients`).
  List<Client> get accountClients => ref.read(accountClientsProvider);

  /// The client whose HTTP client is closed with this state. `ref` is unsafe
  /// in `dispose`, so it is kept here as the accounts change.
  Client? _httpClientOwner;

  Client? _currentHttpClientOwner() =>
      ref.read(activeMatrixClientProvider) ??
      ref.read(accountClientsProvider).firstOrNull;

  Client get _workingClient => _switchCoordinator.target ?? client;

  String? get authUrl => _authUrl;

  Client get client =>
      ref.read(activeMatrixClientProvider) ?? accountClients.first;

  /// Null-safe accessor for the active client.
  ///
  /// Returns the same client as [client] whenever any account exists, but
  /// returns null instead of throwing [StateError] on an empty account list
  /// (a logged-out boot with `clients: []`).
  Client? get clientOrNull => accountClients.isEmpty ? null : client;

  /// True only when an account exists AND it is logged in.
  /// Safe to call during a logged-out boot (returns false on empty clients).
  bool isLoggedInClient() => clientOrNull?.isLogged() ?? false;

  // TODO: 28Dec2023 Disable until support voip
  bool get webrtcIsSupported => false;

  // VoipPlugin? voipPlugin;

  bool get isMultiAccount => accountClients.length > 1;

  int getClientIndexByMatrixId(String matrixId) =>
      accountClients.indexWhere((client) => client.userID == matrixId);

  late String currentClientSecret;
  RequestTokenResponse? currentThreepidCreds;
  String? supportChatRoomId;

  Future<SetActiveClientState> setActiveClient(Client? newClient) async {
    final id = newClient?.clientName;
    if (newClient == null || !accountClients.any((c) => c.clientName == id)) {
      Logs().w(
        'Tried to set an unknown client ${newClient?.clientName} as active',
      );
      return SetActiveClientState.unknownClient;
    }
    // The lookup in progress belongs to the account being left.
    final before = ref.read(accountsProvider);
    if (before is Active && before.activeId != id) {
      unawaited(cancelContactsLookup());
    }
    // Always through the notifier, which orders the calls: asking for the
    // account that is active now still cancels a switch away from it that is
    // queued but not started, so the last request wins.
    try {
      await ref.read(accountsProvider.notifier).switchTo(AccountId(id!));
    } on UnknownAccountException {
      return SetActiveClientState.unknownClient;
    } on InvalidAccountTransitionException catch (e) {
      Logs().w(
        'Cannot switch to client ${newClient.clientName}: '
        '${e.transition} is not allowed from ${e.stateName}',
      );
      return SetActiveClientState.unavailable;
    }
    final accounts = ref.read(accountsProvider);
    if (accounts is Active && accounts.activeId == id) {
      await _switchCoordinator.activateCurrent();
    }
    return SetActiveClientState.success;
  }

  // The switch side effects: the coordinator decides when and in which order,
  // these are the bodies that need this state's context and interceptors.
  @override
  Future<void> setUpToM(Client client, SwitchToken token) =>
      _setUpToMServicesWhenChangingActiveClient(client, token);

  @override
  Future<void> persistActiveAccount(Client client, SwitchToken token) =>
      _storePersistActiveAccount(client, token);

  @override
  Future<void> loadUserInfo(Client client, SwitchToken token) =>
      _getUserInfoWithActiveClient(client, token);

  @override
  Future<void> loadHomeserverInfo(Client client, SwitchToken token) =>
      _getHomeserverInformation(client, token);

  @override
  void refreshContacts(Client client) {
    _rememberContactOwner(client);
    final userId = client.userID;
    if (userId != null) {
      unawaited(ref.read(contactSyncServiceProvider(userId)).refresh());
    }
  }

  @override
  void configureSentryUser(Client client) => Sentry.configureScope(
    (scope) =>
        scope.setUser(SentryUser(username: client.userID, name: client.userID)),
  );

  @override
  void createSupportChat(Client client) {
    Object createSupportChatState = CreateSupportChatInitial();
    supportChatRoomId = null;
    StreamSubscription? syncListener;
    syncListener = client.onSync.stream.listen((_) {
      if (createSupportChatState is! CreateSupportChatInitial) return;
      createSupportChatState = CreatingSupportChat();
      StreamSubscription? createSupportChatListener;
      createSupportChatListener = getIt
          .get<CreateSupportChatInteractor>()
          .execute(
            client,
            cachedDiscovery: loginHomeserverSummary?.discoveryInformation,
          )
          .listen(
            (state) {
              createSupportChatState = state.fold(
                (failure) => failure,
                (success) => success,
              );
              supportChatRoomId = state.fold(
                (failure) => null,
                (success) => switch (success) {
                  SupportChatExisted(:final roomId) => roomId,
                  SupportChatCreated(:final roomId) => roomId,
                  _ => null,
                },
              );
            },
            onDone: () {
              createSupportChatListener?.cancel();
              syncListener?.cancel();
            },
          );
    });
  }

  /// Callback will be called on presence update and return latest value.
  final CachedStreamController<CachedPresence> onLatestPresenceChanged =
      CachedStreamController();
  StreamSubscription? _presenceSubscription;

  @override
  void listenPresence(Client client) {
    _presenceSubscription?.cancel();
    _presenceSubscription = client.onSync.stream.listen((sync) {
      // Deduplicate per user: keep only the most recent presence per userid
      // to avoid UI flickering when a sync contains multiple events for the
      // same user, while still emitting updates for every user in the sync.
      final latestPerUser = <String, CachedPresence>{};

      for (final newPresence in sync.presence ?? []) {
        final cachedPresence = CachedPresence.fromMatrixEvent(newPresence);
        final userId = cachedPresence.userid;
        final existing = latestPerUser[userId];
        final newTs = cachedPresence.lastActiveTimestamp;
        final oldTs = existing?.lastActiveTimestamp;
        if (existing == null ||
            (newTs != null &&
                (oldTs == null ||
                    newTs.isAfter(oldTs) ||
                    newTs.isAtSameMomentAs(oldTs))) ||
            (newTs == null && oldTs == null)) {
          latestPerUser[userId] = cachedPresence;
        }
      }

      for (final presence in latestPerUser.values) {
        onLatestPresenceChanged.add(presence);
      }
    });
  }

  /// A fresh copy on every call: callers filter it in place.
  List<Client?> get currentClients => List<Client?>.from(accountClients);

  /// The unlogged client a login screen uses: the placeholder of a logged-out
  /// boot, else the pending candidate, else a new one. An account that waits
  /// for its removal is never it.
  Future<Client> getLoginClient() async {
    final reusable = ref.read(loginCandidateProvider);
    if (reusable != null) return reusable;

    final account = await ref.read(accountRepositoryProvider).createCandidate();
    final candidate = ref.read(accountClientRegistryProvider)[account.id]!;
    ref.read(pendingLoginCandidateProvider.notifier).set(account.id);
    candidate.onLoginStateChanged.stream
        .where((l) => l == LoginState.loggedIn)
        .first
        .then((state) => _handleAddAnotherAccount(candidate, state))
        .catchError(
          (e, s) => Logs().wtf(
            'MatrixState::getLoginClient: add-account handler failed',
            e,
            s,
          ),
        );
    return candidate;
  }

  Client? getClientByUserId(String userId) =>
      accountClients.firstWhereOrNull((c) => c.userID == userId);

  Client? getClientByName(String name) =>
      accountClients.firstWhereOrNull((c) => c.clientName == name);

  Map<String, dynamic>? shareContent;

  List<Map<String, dynamic>?> get shareContentList => _shareContentList ?? [];

  set shareContentList(List<Map<String, dynamic>?>? content) {
    _shareContentList = content;
  }

  void clearShareContentList() {
    _shareContentList = null;
  }

  List<Map<String, dynamic>?>? _shareContentList;

  File? wallpaper;

  void _initWithStore() async {
    if (clientOrNull == null) return;
    try {
      if (client.isLogged()) {
        // TODO: Figure out how this works in multi account
        final statusMsg = await store.getItem(SettingKeys.ownStatusMessage);
        if (statusMsg?.isNotEmpty ?? false) {
          Logs().v('Send cached status message: "$statusMsg"');
          await client.setPresence(
            client.userID!,
            PresenceType.online,
            statusMsg: statusMsg,
          );
        }
      }
    } catch (e, s) {
      client.onLoginStateChanged.addError(e, s);
      rethrow;
    }
  }

  /// Owned by providers (`account_services_providers.dart`); read once in
  /// `initState` because `ref` is unsafe in `dispose`.
  late final ClientSubscriptions _subscriptions;
  late final LogoutRemovals _logoutRemovals;
  late final LogoutRemovals _pushRemovals;
  late final PushRemovalsController _pushController;
  late final PushTeardown _pushTeardown = _MatrixPushTeardown(this);

  final _lastSyncErrorSentAt = <String, DateTime>{};

  static const _syncErrorSentryThrottle = Duration(minutes: 10);

  /// Re-registers the Web Push pusher when the app language changes so its
  /// (generic) notification text follows the account language.
  VoidCallback? _webPushLocaleListener;
  final StreamController<ClientLoginStateEvent> onClientLoginStateChanged =
      StreamController.broadcast();
  StreamSubscription<html.Event>? onFocusSub;
  StreamSubscription<html.Event>? onBlurSub;
  final initSettingsCompleter = Completer<void>();
  bool _hasSetupSharingStreams = false;

  String? _cachedPassword;
  Timer? _cachedPasswordClearTimer;

  String? get cachedPassword => _cachedPassword;

  set cachedPassword(String? p) {
    Logs().d('Password cached');
    _cachedPasswordClearTimer?.cancel();
    _cachedPassword = p;
    _cachedPasswordClearTimer = Timer(const Duration(minutes: 10), () {
      _cachedPassword = null;
      Logs().d('Cached Password cleared');
    });
  }

  bool webHasFocus = true;

  String? get activeRoomId {
    final path = TwakeApp.router.routeInformationProvider.value.uri.path;
    if (!path.startsWith('/rooms/')) return null;
    return path.split('/')[2];
  }

  final linuxNotifications = PlatformInfos.isLinux
      ? NotificationsClient()
      : null;
  final Map<String, int> linuxNotificationIds = {};

  @override
  void initState() {
    super.initState();
    // The boot clients and the persisted state are overridden by `main` when
    // the container is made; the account state adopts them on its first read.
    _subscriptions = ref.read(clientSubscriptionsProvider);
    _logoutRemovals = ref.read(logoutRemovalsProvider);
    _pushRemovals = ref.read(pushRemovalsProvider);
    // The coordinator registers the switch handler when it is read. It reads
    // the effects only when a switch runs, so they are set right after the
    // first build: a provider cannot be written while the tree is building.
    _switchEffects = ref.read(accountSwitchEffectsProvider.notifier);
    _pushController = ref.read(pushRemovalsControllerProvider.notifier);
    _switchCoordinator = ref.read(accountSwitchCoordinatorProvider);
    _httpClientOwner = _currentHttpClientOwner();
    ref.listenManual(
      accountsProvider,
      (_, _) => _httpClientOwner = _currentHttpClientOwner(),
    );
    _preloadMessageAlignmentSetting();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        _switchEffects.set(this);
        _pushController.setTeardown(_pushTeardown);
      }
      WidgetsBinding.instance.addObserver(this);
      if (PlatformInfos.isWeb) {
        html.window.addEventListener('focus', onWindowFocus);
        html.window.addEventListener('blur', onWindowBlur);
        html.document.addEventListener('visibilitychange', onVisibilityChange);
        FocusManager.instance.addListener(_onFocusManagerChange);
      }
      await initMatrix();
      final emojiRawData = await EmojiData.builtIn();
      emojiData = emojiRawData.filterByVersion(13.5);
      await tryToGetFederationConfigurations();
      if (PlatformInfos.isWeb) {
        initConfigWeb().then((_) => initSettings());
      } else {
        initConfigMobile().then((_) => initSettings());
      }
    });
  }

  void initLoadingDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LoadingDialog.defaultOnError = (e) =>
          (e as Object?)!.toLocalizedString(context);
    });
  }

  /// Sets up sharing intent stream listeners and caches initial values
  /// This should be called as soon as the app opens
  /// Both file and URI streams are set up immediately and cache all incoming values
  /// Cached values are processed after _trySync completes
  ///
  /// IMPORTANT: This method must be awaited to ensure initial intents are
  /// cached before processCachedSharingIntents() is called.
  Future<void> _setupSharingStreamsOnce() async {
    if (_hasSetupSharingStreams) return;
    Logs().d(
      'MatrixState::_setupSharingStreamsOnce: Setting up sharing intent streams',
    );
    try {
      await setupSharingIntentStreams();
      _hasSetupSharingStreams = true;
    } catch (e, s) {
      Logs().wtf(
        'MatrixState::_setupSharingStreamsOnce: Failed to setup sharing streams',
        e,
        s,
      );
      // Optionally rethrow if this is critical
    }
  }

  Future<void> _registerSubs(String name) async {
    final currentClient = getClientByName(name);
    if (currentClient == null) {
      Logs().w(
        'Attempted to register subscriptions for non-existing client $name',
      );
      return;
    }
    // Open before the first await: a cancel that comes while the database is
    // built must find it open, and keep nothing after it.
    _subscriptions.open(name);
    if (PlatformInfos.isMobile) {
      await HiveCollectionToMDatabase.databaseBuilder();
    }
    _subscriptions.keep(
      name,
      'roomKeyRequest',
      () => currentClient.onRoomKeyRequest.stream.listen((
        RoomKeyRequest request,
      ) async {
        if (accountClients.any(
          ((cl) =>
              cl.userID == request.requestingDevice.userId &&
              cl.identityKey == request.requestingDevice.curve25519Key),
        )) {
          Logs().i(
            '[Key Request] Request is from one of our own clients, forwarding the key...',
          );
          await request.forwardKey();
        }
      }).cancel,
    );
    _subscriptions.keep(
      name,
      'keyVerificationRequest',
      () => currentClient.onKeyVerificationRequest.stream.listen((
        KeyVerification request,
      ) async {
        var hidPopup = false;
        request.onUpdate = () {
          if (!hidPopup &&
              {
                KeyVerificationState.done,
                KeyVerificationState.error,
              }.contains(request.state)) {
            Navigator.of(context).pop('dialog');
          }
          hidPopup = true;
        };
        request.onUpdate = null;
        hidPopup = true;
        await KeyVerificationDialog(request: request).show(
          TwakeApp.router.routerDelegate.navigatorKey.currentContext ?? context,
        );
      }).cancel,
    );
    _subscriptions.keep(
      name,
      'loginState',
      () => currentClient.onLoginStateChanged.stream
          .listen((state) => _listenLoginStateChanged(state, currentClient))
          .cancel,
    );
    _subscriptions.keep(
      name,
      'uiaRequest',
      () => currentClient.onUiaRequest.stream.listen(uiaRequestHandler).cancel,
    );
    _subscriptions.keep(
      name,
      'syncStatus',
      () => currentClient.onSyncStatus.stream
          .listen((update) => _handleSyncStatusUpdate(currentClient, update))
          .cancel,
    );
    _subscriptions.keep(
      name,
      'toDeviceEvent',
      () => currentClient.onToDeviceEvent.stream.listen((deviceEvent) {
        if (deviceEvent.type == TwakeEventTypes.addressBookUpdatedEventType) {
          final senderId = deviceEvent.senderId;
          Logs().d(
            '[MATRIX]: onToDeviceEvent:: addressBookUpdatedEventType: senderDevice = $senderId',
          );
          if (currentClient.deviceID != senderId &&
              currentClient.userID != null) {
            unawaited(
              ref
                  .read(contactSyncServiceProvider(currentClient.userID!))
                  .refresh(),
            );
          }
        }
      }).cancel,
    );
    if (PlatformInfos.isWeb || PlatformInfos.isLinux) {
      // The pusher is registered while the name is open; one that finishes
      // after a rollback or a logout is deleted again.
      Future<void> setUpWebPush() => _subscriptions.runGuarded(
        name,
        setUp: () => setupWebPush(currentClient),
        undo: () => removeWebPush(currentClient, unsubscribe: false),
      );
      void setUpWebPushReported() => unawaited(
        setUpWebPush().catchError(
          (Object e, StackTrace s) => _report(e, s, 'web push of $name'),
        ),
      );

      Future<void> initWebNotifications() async {
        // Cancelled (a rollback, a logout) before this ran: set nothing up.
        if (!_subscriptions.isOpen(name)) return;
        if (kIsWeb) {
          setUpWebPushReported();
          // Re-register on language change (and once the locale resolves after
          // a cold start) so the generic notification text matches the account
          // language. removeListener+addListener keeps a single live listener.
          final listener = _webPushLocaleListener;
          if (listener != null) {
            LocalizationService.currentLocale.removeListener(listener);
          }
          _webPushLocaleListener = setUpWebPushReported;
          LocalizationService.currentLocale.addListener(
            _webPushLocaleListener!,
          );
        } else {
          await _requestNotificationPermission();
        }
        // The permission prompt can outlast the login: `keep` starts nothing
        // for a name that was closed meanwhile.
        _subscriptions.keep(
          name,
          'notification',
          () => currentClient.onEvent.stream
              .where(
                (e) =>
                    e.type == EventUpdateType.timeline &&
                    EventTypeRules.messageContentTypes.contains(
                      e.content['type'],
                    ) &&
                    e.content['sender'] != currentClient.userID,
              )
              .listen(showLocalNotification)
              .cancel,
        );
      }

      // On a warm start the first sync may already have happened before this
      // listener attaches, so onSync.stream.first would never fire and web push
      // setup would silently be skipped. Run immediately if already synced.
      if (currentClient.prevBatch != null) {
        await initWebNotifications();
      } else {
        // Waits for a sync that may never come: the wait is cancelled with the
        // other subscriptions of the client.
        _subscriptions.keepOnce(
          name,
          'firstSync',
          currentClient.onSync.stream,
          () => initWebNotifications().catchError(
            (Object e, StackTrace s) => _report(e, s, 'notifications of $name'),
          ),
        );
      }
    }
  }

  void _handleSyncStatusUpdate(Client client, SyncStatusUpdate update) {
    if (update.status != SyncStatus.error || update.error == null) return;

    _captureSyncError(client, update);
  }

  void _captureSyncError(Client client, SyncStatusUpdate update) {
    final error = update.error;
    if (error == null) return;

    final exception = error.exception ?? Exception('Unknown Matrix sync error');
    final errorType = exception.runtimeType.toString();
    final throttleKey = '${client.clientName}:$errorType';
    final now = DateTime.now();
    final lastSentAt = _lastSyncErrorSentAt[throttleKey];
    if (lastSentAt != null &&
        now.difference(lastSentAt) < _syncErrorSentryThrottle) {
      return;
    }

    _lastSyncErrorSentAt[throttleKey] = now;
    // ignore: unawaited_futures
    Sentry.captureException(
      Exception('Matrix sync error: $errorType'),
      withScope: (scope) async {
        await scope.setTag('sync_status', update.status.name);
        await scope.setTag('sync_error_type', errorType);
        await scope.setContexts('matrix_sync', {
          'has_prev_batch': client.prevBatch != null,
          'has_sync_value': client.onSync.value != null,
          'is_logged': client.isLogged(),
          'platform': PlatformInfos.clientName,
          'sync_pending': client.syncPending,
        });
      },
    );
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final isInsideCozy = await CozyConfigManager().isInsideCozy;
      if (isInsideCozy) {
        CozyConfigManager().requestNotificationPermission();
        return;
      }
    } catch (_) {}

    await html.Notification.requestPermission();
  }

  Future<void> _listenLoginStateChanged(LoginState state, Client client) async {
    final loggedInWithMultipleClients = accountClients.length > 1;
    if (loggedInWithMultipleClients && state != LoginState.loggedIn) {
      await _handleLogoutWithMultipleAccount(state, client);
    } else {
      if (state == LoginState.loggedIn) {
        Logs().v('[MATRIX]:_listenLoginStateChanged:: First Log in successful');
        // Not awaited: the session queues this behind a rollback that is
        // cancelling this very listener, and cancelling waits for the handlers.
        // The session never throws and is awaited by its own queue.
        unawaited(_handleFirstLoggedIn(client, state));
      } else {
        Logs().v('[MATRIX]:_listenLoginStateChanged:: Last Log out successful');
        await _handleLastLogout(loggedOut: client);
      }
    }
  }

  Future<void> _handleLogoutWithMultipleAccount(
    LoginState state,
    Client currentClient,
  ) async {
    waitForFirstSync = false;
    try {
      await _removePush(currentClient);
    } catch (e, s) {
      _report(e, s, 'push removal of ${currentClient.clientName}');
    }
    await _removeLoggedOutAccount(state, currentClient);
  }

  /// Push registration of an account that goes away: the keychain sync of iOS,
  /// the pusher (it needs a session that is still open) and, on web, the
  /// pusher of this account only: the shared browser subscription stays for
  /// the accounts still signed in. Throws when a pusher cannot be deleted.
  Future<void> _removePush(Client target) async {
    if (PlatformInfos.isIOS) {
      await backgroundPush?.cancelKeychainSyncForClient(target);
    }
    if (PlatformInfos.isMobile && target.isLogged()) {
      await backgroundPush?.removePusherForClient(target);
    }
    if (kIsWeb) await removeWebPush(target, unsubscribe: false);
  }

  /// Pusher deletions that failed before the last exit run again now, for the
  /// accounts whose session is still open; a record whose account is gone
  /// cannot be retried and is dropped.
  Future<void> _retryPendingPushRemovalsFromLastRun() async {
    final registry = ref.read(accountClientRegistryProvider);
    try {
      final retryable = await ref
          .read(prunePendingPushRemovalsUseCaseProvider)
          .execute();
      for (final id in retryable) {
        final pending = registry[id];
        if (pending != null) await _pushController.removeBeforeLogout(pending);
      }
    } catch (e, s) {
      _report(e, s, 'retry of the pending pusher deletions');
    }
  }

  /// Removes the account that logged out. Every step (the wait for a switch,
  /// the subscriptions, the removal, holding the account as unavailable, the
  /// record that survives a restart, the effects of the change) runs again on
  /// its own when it fails, in the background and after a restart, until it
  /// works; meanwhile the account is listed as unavailable and cannot be
  /// switched to.
  Future<void> _removeLoggedOutAccount(
    LoginState state,
    Client currentClient, {
    bool announce = true,
  }) async {
    await _logoutRemovals.remove(
      currentClient.clientName,
      LogoutRemovalPlan(
        id: currentClient.clientName,
        accounts: ref.read(accountsProvider.notifier),
        isActive: () => ref.read(activeMatrixClientProvider) == currentClient,
        cancelSubscriptions: () => _cancelSubs(currentClient.clientName),
        activateReplacement: () => _activateAfterLogout(state, currentClient),
        announce: announce ? () => _announceLogout(currentClient) : null,
      ).steps,
      _report,
    );
  }

  /// The accounts whose removal did not finish before the app was closed are
  /// removed again now, and again in the background until it works. They stay
  /// listed even when nobody is logged in, so the state is the list to read.
  void _retryPendingRemovalsFromLastRun() {
    final registry = ref.read(accountClientRegistryProvider);
    for (final account in ref.read(accountsProvider).accounts) {
      if (account.status != AccountStatus.unavailable) continue;
      final pending = registry[account.id];
      if (pending == null) continue;
      unawaited(
        _removeLoggedOutAccount(LoginState.loggedOut, pending, announce: false),
      );
    }
  }

  Future<void> _announceLogout(Client loggedOut) async {
    await _clearContactsOf(loggedOut);
    if (!mounted) return;
    TwakeSnackBar.show(
      TwakeApp.routerKey.currentContext!,
      L10n.of(context)!.oneClientLoggedOut,
    );
  }

  /// The active account is gone or held: the account that takes its place
  /// gets the shared effects, or, with none logged in, the app goes where the
  /// last logout goes.
  Future<void> _activateAfterLogout(
    LoginState state,
    Client currentClient,
  ) async {
    if (ref.read(accountsProvider) is NoAccount) {
      await _handleLastLogout(loggedOut: currentClient);
      return;
    }
    final newActiveClient = client;
    await _switchCoordinator.apply(newActiveClient);
    // Push serves one account: the replacement gets its pusher now.
    if (PlatformInfos.isMobile && newActiveClient.isLogged()) {
      backgroundPush?.rebindFrom(currentClient, newActiveClient);
    }
    Logs().v(
      '[MATRIX]:_handleLogoutWithMultipleAccount:: Log out Client ${currentClient.clientName} successful',
    );
    if (state != LoginState.loggedIn) {
      TwakeApp.router.go(
        '/rooms',
        extra: LogoutBodyArgs(newActiveClient: newActiveClient),
      );
    }
  }

  /// Makes a failure visible. `Logs().wtf` is what the error reporting picks
  /// up (`SentryLogger`), so it is sent once.
  void _report(Object error, StackTrace stackTrace, String what) =>
      Logs().wtf('MatrixState: $what', error, stackTrace);

  /// A new session opened for [id]: a pusher deletion kept from the session
  /// before would run against this one, so it is dropped with its record.
  Future<void> _dropKeptPushRemoval(String id) async {
    if (!_pushRemovals.forget(id)) return;
    try {
      await ref.read(accountRepositoryProvider).clearPushRemovalPending(id);
    } catch (e, s) {
      _report(e, s, 'record of the dropped pusher deletion of $id');
    }
  }

  Future<void> _handleFirstLoggedIn(
    Client newActiveClient,
    LoginState loginState,
  ) async {
    waitForFirstSync = false;
    await _dropKeptPushRemoval(newActiveClient.clientName);
    _rememberContactOwner(newActiveClient);
    try {
      await ref
          .read(accountsProvider.notifier)
          .addAccount(AccountId(newActiveClient.clientName));
    } catch (e, s) {
      Logs().wtf('MatrixState::_handleFirstLoggedIn: cannot add account', e, s);
      return;
    }
    await setUpToMServicesInLogin(newActiveClient);
    await setUpFederationServicesInLogin(newActiveClient);
    // Also refreshes the contacts of the new account (refreshContacts).
    await _switchCoordinator.activateCurrent();
    // The first login of a boot that had nobody logged in.
    _ensureBackgroundPush();
    onClientLoginStateChanged.add(
      ClientLoginStateEvent(
        client: client,
        loginState: loginState,
        multipleAccountLoginType: MultipleAccountLoginType.firstLoggedIn,
      ),
    );
  }

  Future<void> _handleAddAnotherAccount(
    Client candidate,
    LoginState loginState,
  ) async {
    Logs().d(
      'MatrixState::_handleAddAnotherAccount() - Add another account successful',
    );
    await ref
        .read(accountsProvider.notifier)
        .addAccount(AccountId(candidate.clientName));
    await _registerSubs(candidate.clientName);
    final activeClient = getClientByName(candidate.clientName);
    if (activeClient == null) return;
    waitForFirstSync = false;
    _rememberContactOwner(activeClient);
    await setUpToMServicesInLogin(activeClient);
    await setUpFederationServicesInLogin(activeClient);

    if (PlatformInfos.isIOS) {
      await backgroundPush?.syncRecoveryKeyForClient(activeClient);
    }

    final result = await setActiveClient(activeClient);

    // The first account after a time with nobody logged in gets the push set
    // up like a first login; else only iOS sets push up for an additional one.
    if (!_ensureBackgroundPush() && PlatformInfos.isIOS) {
      await backgroundPush?.setupPushForAdditionalClient(activeClient);
    }

    await cancelContactsLookup();
    if (result.isSuccess) {
      onClientLoginStateChanged.add(
        ClientLoginStateEvent(
          client: client,
          loginState: loginState,
          multipleAccountLoginType:
              MultipleAccountLoginType.otherAccountLoggedIn,
        ),
      );
      ref.read(pendingLoginCandidateProvider.notifier).set(null);
    }
  }

  Future<void> _deletePersistActiveAccount() async {
    try {
      await ref.read(accountRepositoryProvider).clearPersistedActiveAccount();
      Logs().d(
        'MatrixState::_handleLogoutWithMultipleAccount: Delete persist active account success',
      );
    } catch (e, s) {
      Logs().wtf('MatrixState::_handleLogoutWithMultipleAccount: Error', e, s);
    }
  }

  Future<void> _cancelSubs(String name) async {
    // The listener goes first: a failing cancel below must not leave it live.
    final webPushListener = _webPushLocaleListener;
    if (webPushListener != null) {
      LocalizationService.currentLocale.removeListener(webPushListener);
      _webPushLocaleListener = null;
    }
    await _subscriptions.cancel(name);
  }

  /// Makes the push service serve the active client once it is logged in: it
  /// creates the service, or, when the one that exists did not set push up
  /// (the boot had nobody logged in, or the last account logged out since),
  /// binds it to this client. A boot with no logged-in account has nothing to
  /// push for, so the service is never bound to a client that cannot receive
  /// push. Returns true when it set push up for the active client.
  bool _ensureBackgroundPush() {
    final pushClient = clientOrNull;
    if (!PlatformInfos.isMobile ||
        pushClient == null ||
        !pushClient.isLogged()) {
      return false;
    }
    final existing = backgroundPush;
    if (existing != null) {
      if (existing.isSetUp) return false;
      existing.rebind(pushClient);
      return true;
    }
    backgroundPush = BackgroundPush(
      this,
      pushClient,
      onFcmError: (errorMsg, {Uri? link}) async {
        final result = await showOkCancelAlertDialog(
          barrierDismissible: true,
          context: context,
          title: L10n.of(context)!.oopsSomethingWentWrong,
          message: errorMsg,
          okLabel: link == null ? L10n.of(context)!.ok : L10n.of(context)!.help,
          cancelLabel: L10n.of(context)!.doNotShowAgain,
        );
        if (result == OkCancelResult.ok && link != null) {
          UrlLauncher(context, url: link.toString()).openUrlInAppBrowser();
        }
        if (result == OkCancelResult.cancel) {
          await store.setItemBool(SettingKeys.showNoGoogle, true);
        }
      },
    );
    return true;
  }

  Future<void> initMatrix() async {
    // Display the app lock
    if (PlatformInfos.isMobile) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ([TargetPlatform.linux].contains(Theme.of(context).platform)
                ? SharedPreferences.getInstance().then(
                    (prefs) => prefs.getString(SettingKeys.appLockKey),
                  )
                : const FlutterSecureStorage().read(
                    key: SettingKeys.appLockKey,
                  ))
            .then((lock) {
              if (lock?.isNotEmpty ?? false) {
                AppLock.of(context)!.enable();
                AppLock.of(context)!.showLockScreen();
              }
            });
      });
    }

    _initWithStore();

    for (final c in accountClients) {
      Logs().d('MatrixState::initMatrix: ${c.clientName} calling registerSubs');
      try {
        await _registerSubs(c.clientName);
      } catch (e, s) {
        _report(e, s, 'subscriptions of ${c.clientName}');
      }
      _rememberContactOwner(c);
    }
    _retryPendingRemovalsFromLastRun();

    await _retrieveLocalToMConfiguration();

    // Refresh only once the ToM URL/token of the restored account are applied:
    // the ToM sources would otherwise fail and put their contacts in cooldown.
    // A logged-out client (fresh install) has no userID yet; its first
    // refresh runs in _handleFirstLoggedIn once the login completes.
    final initialUserId = clientOrNull?.userID;
    if (initialUserId != null) {
      unawaited(ref.read(contactSyncServiceProvider(initialUserId)).refresh());
    }

    if (kIsWeb) {
      onFocusSub = html.window.onFocus.listen((_) => webHasFocus = true);
      onBlurSub = html.window.onBlur.listen((_) => webHasFocus = false);
    }

    _ensureBackgroundPush();
    // After the push set-up started: before it, no pusher can be deleted.
    unawaited(_retryPendingPushRemovalsFromLastRun());

    createVoipPlugin();

    // Set up sharing intent stream listeners (Part 2)
    // This happens immediately when app opens, regardless of login state
    await _setupSharingStreamsOnce();
  }

  @override
  void createVoipPlugin() async {
    // if (await store.getItemBool(SettingKeys.experimentalVoip) == false) {
    //   voipPlugin = null;
    //   return;
    // }
    // voipPlugin = webrtcIsSupported ? VoipPlugin(client) : null;
  }

  Future<ToMConfigurations?> getTomConfigurations(String userID) async {
    try {
      final tomConfigurationRepository = getIt
          .get<ToMConfigurationsRepository>();
      final toMConfigurations = await tomConfigurationRepository
          .getTomConfigurations(userID);
      return toMConfigurations;
    } catch (e, s) {
      Logs().wtf('MatrixState::_getTomConfigurations:', e, s);
    }
    return null;
  }

  Future<FederationConfigurations?> getFederationConfigurations(
    String userId,
  ) async {
    try {
      final federationConfigurationRepository = getIt
          .get<FederationConfigurationsRepository>();
      final federationConfigurations = await federationConfigurationRepository
          .getFederationConfigurations(userId);
      return federationConfigurations;
    } catch (e, s) {
      Logs().wtf('MatrixState::_getFederationConfigurations:', e, s);
    }
    return null;
  }

  Future<void> _retrieveLocalToMConfiguration() async {
    if (clientOrNull == null) return;
    if (client.userID == null) return;

    // Matrix APIs must remain available even when no optional ToM
    // configuration has been stored for the current user yet.
    setUpAuthorization(client);
    if (client.homeserver != null) {
      _setUpHomeServer(client.homeserver!);
    }

    try {
      final toMConfigurations =
          await getTomConfigurations(client.userID!) ??
          await _discoverFreshInstallToMConfiguration(client);
      if (toMConfigurations == null) {
        // No ToM server for this account: drop any configuration left over
        // from a previously active account (multi-account switch).
        _setUpToMServer(null);
        _setupAuthUrl();
        return;
      }
      setUpToMServices(
        toMConfigurations.tomServerInformation,
        toMConfigurations.identityServerInformation,
      );
      _setupAuthUrl(url: toMConfigurations.authUrl);
      loginType = toMConfigurations.loginType;
    } catch (e, s) {
      Logs().wtf('MatrixState::_retrieveToMConfiguration:', e, s);
    }
  }

  /// Fresh-install bootstrap: no ToM configuration has been stored for the
  /// current account yet, so the active homeserver discovery is the source of
  /// truth. When a ToM server is discovered, the configuration is persisted
  /// so later boots stay local-only. Returns `null` for non-ToM accounts.
  Future<ToMConfigurations?> _discoverFreshInstallToMConfiguration(
    Client client,
  ) async {
    await _getHomeserverInformation(client);
    final tomServer = loginHomeserverSummary?.tomServer;
    if (tomServer == null) return null;

    final discovery = loginHomeserverSummary?.discoveryInformation;
    _setupAuthUrl();
    final toMConfigurations = ToMConfigurations(
      tomServerInformation: tomServer,
      identityServerInformation: discovery?.mIdentityServer,
      authUrl: authUrl,
      loginType: loginType,
    );
    await _storeToMConfiguration(client, toMConfigurations);
    return toMConfigurations;
  }

  void setUpToMServices(
    ToMServerInformation tomServer,
    IdentityServerInformation? identityServer, {
    Client? forClient,
  }) {
    Logs().d(
      'MatrixState::setUpToMServices: $tomServer, ${identityServer?.baseUrl}',
    );
    _setUpToMServer(tomServer);
    if (identityServer != null) {
      _setUpIdentityServer(identityServer);
    }
    final working = forClient ?? _workingClient;
    setUpAuthorization(working);
    if (working.homeserver != null) {
      _setUpHomeServer(working.homeserver!);
    }
  }

  Future<void> setUpToMServicesInLogin(Client client) async {
    final tomServer = loginHomeserverSummary?.tomServer;
    Logs().d('MatrixState::setUpToMServicesInLogin: $tomServer');
    if (tomServer != null) {
      _setUpToMServer(tomServer);
    }
    final identityServer =
        loginHomeserverSummary?.discoveryInformation?.mIdentityServer;
    final homeServer =
        loginHomeserverSummary?.discoveryInformation?.mHomeserver.baseUrl ??
        client.homeserver;
    _setupAuthUrl();
    if (identityServer != null) {
      _setUpIdentityServer(identityServer);
    }
    if (homeServer != null) {
      _setUpHomeServer(homeServer);
    }
    if (tomServer != null) {
      await _storeToMConfiguration(
        client,
        ToMConfigurations(
          tomServerInformation: tomServer,
          identityServerInformation: identityServer,
          authUrl: authUrl,
          loginType: loginType,
        ),
      );
    }
    setUpAuthorization(client);
  }

  Future<void> setUpFederationServicesInLogin(Client client) async {
    final federationSever = loginHomeserverSummary?.federationServer;
    final identityServer =
        loginHomeserverSummary?.discoveryInformation?.mIdentityServer;
    Logs().d('MatrixState::setUpFederationServicesInLogin: $federationSever');

    if (federationSever != null) {
      await _storeFederationConfiguration(
        client,
        FederationConfigurations(
          fedServerInformation: federationSever,
          identityServerInformation: identityServer,
        ),
      );
    }
  }

  Future<void> tryToGetFederationConfigurations() async {
    if (clientOrNull == null) return;
    if (client.userID == null) return;
    try {
      final federationConfigurationRepository = getIt
          .get<FederationConfigurationsRepository>();
      final federationConfigurations = await federationConfigurationRepository
          .getFederationConfigurations(client.userID!);

      if (federationConfigurations.fedServerInformation.hasBaseUrls) {
        Logs().d(
          'MatrixState::tryToGetFederationConfigurations: ${federationConfigurations.fedServerInformation}',
        );
        return;
      }

      await _tryStoreFederationConfiguration();
    } catch (e, s) {
      Logs().wtf('MatrixState::tryToGetFederationConfigurations:', e, s);

      if (e is FederationConfigurationNotFound) {
        Logs().wtf(
          'MatrixState::tryToGetFederationConfigurations: FederationConfigurationNotFound',
          e,
          s,
        );

        await _tryStoreFederationConfiguration();
      }
    }
  }

  Future<void> _tryStoreFederationConfiguration() async {
    try {
      final wellKnown = loginHomeserverSummary?.discoveryInformation;
      if (wellKnown == null) return;

      Logs().d('MatrixState::_tryStoreFederationConfiguration: $wellKnown');

      final fedServerJson = wellKnown
          .additionalProperties[FederationServerInformation.fedServerKey];

      if (fedServerJson is! Map<String, dynamic>) return;

      final federationConfigurationRepository = getIt
          .get<FederationConfigurationsRepository>();

      await federationConfigurationRepository.saveFederationConfigurations(
        client.userID!,
        FederationConfigurations(
          fedServerInformation: FederationServerInformation.fromJson(
            fedServerJson,
          ),
        ),
      );
    } catch (e, s) {
      Logs().wtf('MatrixState::_tryStoreFederationConfiguration:', e, s);
    }
  }

  void setUpAuthorization(Client client) {
    final authorizationInterceptor = getIt.get<AuthorizationInterceptor>();
    Logs().d(
      'MatrixState::setUpAuthorization: accessToken ${client.accessToken}',
    );
    authorizationInterceptor.accessToken = client.accessToken;
  }

  void _setUpToMServer(ToMServerInformation? tomServer) {
    final tomServerUrlInterceptor = getIt.get<DynamicUrlInterceptors>(
      instanceName: NetworkDI.tomServerUrlInterceptorName,
    );
    Logs().d(
      'MatrixState::_setUpToMServer: ${tomServerUrlInterceptor.hashCode}',
    );
    tomServerUrlInterceptor.changeBaseUrl(tomServer?.baseUrl?.toString());
  }

  void _setUpHomeServer(Uri homeServerUri) {
    final homeServerUrlInterceptor = getIt.get<DynamicUrlInterceptors>(
      instanceName: NetworkDI.homeServerUrlInterceptorName,
    );
    Logs().d(
      'MatrixState::_setUpHomeServer: ${homeServerUrlInterceptor.baseUrl}',
    );
    homeServerUrlInterceptor.changeBaseUrl(homeServerUri.toString());
  }

  void _setUpIdentityServer(IdentityServerInformation identityServer) {
    final identityServerUrlInterceptor = getIt.get<DynamicUrlInterceptors>(
      instanceName: NetworkDI.identityServerUrlInterceptorName,
    );
    Logs().d(
      'MatrixState::_setUpIdentityServer: ${identityServerUrlInterceptor.hashCode}',
    );
    identityServerUrlInterceptor.changeBaseUrl(
      identityServer.baseUrl.toString(),
    );
  }

  Future<void> _storeToMConfiguration(
    Client client,
    ToMConfigurations config,
  ) async {
    try {
      Logs().e(
        'Matrix::_storeToMConfiguration: clientName - ${client.clientName}',
      );
      Logs().e('Matrix::_storeToMConfiguration: userId - ${client.userID}');
      if (client.userID == null) return;
      final ToMConfigurationsRepository configurationRepository = getIt
          .get<ToMConfigurationsRepository>();
      await configurationRepository.saveTomConfigurations(
        client.userID!,
        config,
      );
      Logs().e(
        'Matrix::_storeToMConfiguration: configurationRepository - $configurationRepository',
      );
    } catch (e) {
      Logs().e('Matrix::_storeToMConfiguration: error - $e');
    }
  }

  Future<void> _storeFederationConfiguration(
    Client client,
    FederationConfigurations config,
  ) async {
    try {
      Logs().e(
        'Matrix::_storeFederationConfiguration: clientName - ${client.clientName}',
      );
      Logs().e(
        'Matrix::_storeFederationConfiguration: userId - ${client.userID}',
      );
      if (client.userID == null) return;
      final FederationConfigurationsRepository
      federationConfigurationRepository = getIt
          .get<FederationConfigurationsRepository>();
      await federationConfigurationRepository.saveFederationConfigurations(
        client.userID!,
        config,
      );
      Logs().e(
        'Matrix::_storeFederationConfiguration: configurationRepository - $federationConfigurationRepository',
      );
    } catch (e) {
      Logs().e('Matrix::_storeFederationConfiguration: error - $e');
    }
  }

  /// A token that went stale means a newer switch owns the shared state: the
  /// body stops before its next write. Without a token the call is not part
  /// of a switch and always writes.
  bool _isCurrent(SwitchToken? token) => token?.isCurrent ?? true;

  Future<void> _setUpToMServicesWhenChangingActiveClient(
    Client? client, [
    SwitchToken? token,
  ]) async {
    Logs().d(
      'Matrix::_setUpToMServicesWhenChangingActiveClient: Old twakeSupported - $twakeSupported',
    );
    if (client == null || client.userID == null) return;
    try {
      final toMConfigurations = await getTomConfigurations(client.userID!);
      if (!_isCurrent(token)) return;
      Logs().d(
        'Matrix::_setUpToMServicesWhenChangingActiveClient: toMConfigurations - $toMConfigurations',
      );
      if (toMConfigurations == null) {
        await _retrieveLocalToMConfiguration();
      } else {
        _setupAuthUrl(url: toMConfigurations.authUrl);
        setUpToMServices(
          toMConfigurations.tomServerInformation,
          toMConfigurations.identityServerInformation,
          forClient: client,
        );
      }
    } catch (e, s) {
      if (!_isCurrent(token)) return;
      _setUpToMServer(null);
      _setupAuthUrl();
      setUpAuthorization(client);
      Logs().wtf(
        'Matrix::_setUpToMServicesWhenChangingActiveClient: error',
        e,
        s,
      );
    }
    Logs().d(
      'Matrix::_setUpToMServicesWhenChangingActiveClient: New twakeSupported - $twakeSupported',
    );
  }

  Future<void> retrievePersistedActiveClient() async {
    try {
      await _switchCoordinator.activateCurrent();
    } catch (e, s) {
      Logs().wtf('Matrix::_retrievePersistedActiveAccount(): Error', e, s);
    }
  }

  Future<void> _getUserInfoWithActiveClient(
    Client newClient, [
    SwitchToken? token,
  ]) async {
    if (newClient.userID == null) return;
    try {
      final result = await getIt.get<UserInfoRepository>().getUserInfo(
        Uri.encodeComponent(newClient.userID!),
      );
      if (!_isCurrent(token)) return;

      await LocalizationService.initializeLanguage(
        context,
        serverLanguage: result.language,
      );
    } catch (e, s) {
      Logs().wtf('Matrix::_getUserInfoWithActiveClient(): Error', e, s);
      if (!_isCurrent(token)) return;
      await LocalizationService.initializeLanguage(context);
    }
  }

  Future<void> _getHomeserverInformation(
    Client newClient, [
    SwitchToken? token,
  ]) async {
    Logs().d(
      'Matrix::_getHomeserverInformation: client homeserver = ${newClient.homeserver}',
    );
    if (newClient.homeserver == null) return;
    final previousSummary = loginHomeserverSummary;

    HomeserverSummary? checkedSummary;
    try {
      checkedSummary = await newClient
          .checkHomeserver(newClient.homeserver!, checkWellKnown: false)
          .toHomeserverSummary();
    } catch (e) {
      Logs().w(
        'Matrix::_getHomeserverInformation: homeserver unreachable, using '
        'cached discovery information',
        e,
      );
    }

    final discovery = await newClient.getWellKnownOrFallback(
      fallback: previousSummary?.discoveryInformation,
    );

    if (checkedSummary == null && discovery == null) return;

    // The active client may have changed while awaiting: a late result must
    // not overwrite the newer account's summary.
    if (!_isCurrent(token) ||
        (_switchCoordinator.target ?? clientOrNull) != newClient) {
      return;
    }

    loginHomeserverSummary = HomeserverSummary(
      discoveryInformation: discovery,
      versions:
          checkedSummary?.versions ??
          previousSummary?.versions ??
          GetVersionsResponse(versions: []),
      loginFlows:
          checkedSummary?.loginFlows ?? previousSummary?.loginFlows ?? [],
    );
    Logs().d(
      'Matrix::_getHomeserverInformation: appTwakeInformation ${loginHomeserverSummary?.appTwakeInformation}',
    );
    await _ensureToMServicesFromSummary(newClient, token);
  }

  /// Rebuilds the ToM configuration of an already logged-in session from the
  /// homeserver well-known discovery information.
  ///
  /// The ToM configuration is normally persisted during login. A valid Matrix
  /// session can however outlive that local data (for example when the app
  /// container is reset while the session is kept in the keychain), leaving
  /// the app with `twakeSupported == false`. In that state the ToM URL
  /// interceptor has no host and every `/_twake/*` request fails until the
  /// user logs in again. Re-deriving the configuration from the well-known
  /// keeps the ToM-backed address book working without a new login.
  Future<void> _ensureToMServicesFromSummary(
    Client newClient, [
    SwitchToken? token,
  ]) async {
    if (newClient.userID == null) return;

    final tomServer = loginHomeserverSummary?.tomServer;
    if (tomServer == null) return;

    final tomServerUrlInterceptor = getIt.get<DynamicUrlInterceptors>(
      instanceName: NetworkDI.tomServerUrlInterceptorName,
    );
    if (tomServerUrlInterceptor.baseUrl == tomServer.baseUrl?.toString()) {
      return;
    }

    final identityServer =
        loginHomeserverSummary?.discoveryInformation?.mIdentityServer;
    Logs().d(
      'MatrixState::_ensureToMServicesFromSummary: restoring ToM configuration '
      'from well-known (${tomServer.baseUrl})',
    );
    _setupAuthUrl();
    setUpToMServices(tomServer, identityServer, forClient: newClient);
    await _storeToMConfiguration(
      newClient,
      ToMConfigurations(
        tomServerInformation: tomServer,
        identityServerInformation: identityServer,
        authUrl: authUrl,
        loginType: loginType,
      ),
    );
    if (!_isCurrent(token)) return;
    // The address book may have been synced before the ToM configuration was
    // available, so refresh it now that it is reachable — otherwise the ToM
    // contacts only show up after a manual pull-to-refresh.
    unawaited(
      ref.read(contactSyncServiceProvider(newClient.userID!)).refresh(),
    );
  }

  Future<void> _refreshHomeserverInformation(Client client) async {
    client.homeserver ??= Uri.parse(AppConfig.homeserver);
    await _getHomeserverInformation(client);
  }

  Future<void> _storePersistActiveAccount(
    Client newClient, [
    SwitchToken? token,
  ]) async {
    if (newClient.userID == null || !_isCurrent(token)) return;
    try {
      Logs().d(
        'Matrix::_storePersistActiveAccount: clientName - ${newClient.clientName}',
      );
      Logs().d(
        'Matrix::_storePersistActiveAccount: userId - ${newClient.userID}',
      );
      await ref
          .read(accountRepositoryProvider)
          .persistActiveAccount(newClient.clientName);
    } catch (e, s) {
      Logs().wtf('Matrix::_storePersistActiveAccount(): Error', e, s);
    }
  }

  /// Last focusable leaf [FocusNode] that had focus, updated continuously via
  /// [FocusManager] listener so it stays valid even after the browser clears
  /// DOM focus on tab switch.
  FocusNode? _lastFocusedNode;

  /// Called on every Flutter focus change. Saves only leaf nodes that can
  /// actually receive input (excludes FocusScope and non-focusable nodes).
  void _onFocusManagerChange() {
    final current = FocusManager.instance.primaryFocus;
    if (current != null &&
        current.canRequestFocus &&
        current is! FocusScopeNode) {
      _lastFocusedNode = current;
    }
  }

  /// Restores focus after a post-frame delay so the Flutter engine finishes
  /// its own focus handling (view-level focus) before we override it.
  ///
  /// Re-reads [_lastFocusedNode] inside the callback to avoid overwriting a
  /// newer focus target that may have been set between the call and execution.
  /// Only restores if focus is still effectively unset (null or a FocusScopeNode,
  /// which can't receive keyboard input directly).
  void _restoreFocus() {
    if (_lastFocusedNode == null) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final node = _lastFocusedNode;
      if (node == null || !node.canRequestFocus) return;
      // Only restore if no real (leaf) node has taken focus in the meantime.
      final currentFocus = FocusManager.instance.primaryFocus;
      if (currentFocus == null || currentFocus is FocusScopeNode) {
        node.requestFocus();
      }
    });
  }

  void onWindowFocus(html.Event e) {
    didChangeAppLifecycleState(AppLifecycleState.resumed);
    _restoreFocus();
  }

  void onWindowBlur(html.Event e) {
    didChangeAppLifecycleState(AppLifecycleState.paused);
  }

  void onVisibilityChange(html.Event e) {
    if (html.document.hidden != true) {
      _restoreFocus();
    }
  }

  void _setupAuthUrl({String? url}) {
    if (url != null) {
      Logs().e('Matrix::_setupAuthUrl: newAuthUrl - $url');
      _authUrl = url;
    } else {
      final authData = loginHomeserverSummary
          ?.discoveryInformation
          ?.additionalProperties["m.authentication"];
      final newAuthUrl = authData is Map<String, dynamic>
          ? authData["issuer"]
          : null;
      Logs().e('Matrix::_setupAuthUrl: newAuthUrl - $newAuthUrl');
      _authUrl = newAuthUrl is String ? newAuthUrl : url;
    }
  }

  Future<void> _deleteAllTomConfigurations() async {
    final hiveCollectionToMDatabase = getIt.get<HiveCollectionToMDatabase>();
    await hiveCollectionToMDatabase.clear();
    Logs().d(
      'MatrixState::_deleteAllTomConfigurations: Delete ToM database success',
    );
  }

  Future<void> _handleLastLogout({required Client loggedOut}) async {
    waitForFirstSync = false;
    // Clear first: the last logout rebuilds the contact services, and the wipe
    // must run behind the refresh of the instance that owns it.
    await _clearContactsOf(loggedOut);
    // Nobody is logged in: the next login sets push up again.
    backgroundPush?.forgetSetup();
    if (PlatformInfos.isIOS) {
      try {
        await backgroundPush?.cancelKeychainSyncForClient(loggedOut);
      } catch (e, s) {
        _report(e, s, 'keychain sync cancel of ${loggedOut.clientName}');
      }
    }
    final accounts = ref.read(accountsProvider);
    if (accounts is Active && accounts.accounts.length == 1) {
      await ref.read(accountsProvider.notifier).logoutLast();
    }
    Sentry.configureScope((scope) => scope.setUser(null));
    if (PlatformInfos.isMobile) {
      await _deletePersistActiveAccount();
      TwakeApp.router.go(const HomeTwakeWelcomeRoute().location);
    } else {
      if (kIsWeb) await removeWebPush(loggedOut);
      TwakeApp.router.go(const HomeRoute($extra: true).location, extra: true);
    }
    await _deleteAllTomConfigurations();
  }

  /// Stops the phonebook lookup in progress (logout, account switch): its
  /// results belong to the account that started it.
  Future<void> cancelContactsLookup() =>
      ref.read(phonebookResolverProvider).cancel();

  /// Matrix ID of each signed-in client, by client name. The SDK forgets the
  /// user ID of a client when it logs out, but the contacts it owned must still
  /// be wiped from the store.
  final Map<String, String> _contactOwners = <String, String>{};

  void _rememberContactOwner(Client client) {
    final userId = client.userID;
    if (userId != null) _contactOwners[client.clientName] = userId;
  }

  /// Logout: stops the lookup and removes the account's contacts from the
  /// local store.
  Future<void> _clearContactsOf(Client loggedOutClient) async {
    await cancelContactsLookup();
    final owner =
        _contactOwners.remove(loggedOutClient.clientName) ??
        loggedOutClient.userID;
    if (owner == null) return;
    try {
      await ref.read(contactSyncServiceProvider(owner)).clear();
    } catch (exception, stackTrace) {
      Logs().e('MatrixState::_clearContactsOf', exception, stackTrace);
    }
  }

  void handleShowQrCodeDownload(bool show) {
    showQrCodeDownload.value = show;
  }

  /// Sets up the audio player with auto-dispose listener when playback completes.
  ///
  /// This method should be called after setting up a new audio source.
  /// It automatically cleans up the audio player and resets state when playback finishes.
  void setupAudioPlayerAutoDispose() {
    final currentEvent = voiceMessageEvent.value;
    _audioPlayerStateSubscription?.cancel();
    _audioPlayerStateSubscription = audioPlayer.playerStateStream.listen((
      state,
    ) {
      if (state.processingState == ProcessingState.completed) {
        // Guard against clearing state for a different audio
        if (voiceMessageEvent.value?.eventId != currentEvent?.eventId) {
          return;
        }
        voiceMessageEvent.value = null;
        audioPlayer.stop();
        audioPlayer.dispose();
        currentAudioStatus.value = AudioPlayerStatus.notDownloaded;
      }
    });
  }

  @override
  Future<void> onConnect() async {
    if (clientOrNull == null) return;
    if (client.homeserver != null) return;
    await _refreshHomeserverInformation(client);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    Logs().i('didChangeAppLifecycleState: AppLifecycleState = $state');
    Logs().i('didChangeAppLifecycleState: currentTime: ${DateTime.now()}');
    if (clientOrNull == null) return;
    final foreground =
        state != AppLifecycleState.detached &&
        state != AppLifecycleState.paused;
    client.backgroundSync = foreground;
    client.syncPresence = foreground ? null : PresenceType.unavailable;
    backgroundPush?.clearAllNotifications();
  }

  void _preloadMessageAlignmentSetting() {
    store
        .getItemBool(
          SettingKeys.enableRightAndLeftMessageAlignmentOnWeb,
          AppConfig.enableRightAndLeftMessageAlignmentOnWeb,
        )
        .then((value) {
          if (!mounted ||
              AppConfig.enableRightAndLeftMessageAlignmentOnWeb == value) {
            return;
          }
          // The flag is a plain static that nothing listens to, so a rebuild
          // has to be requested explicitly for already-mounted descendants.
          setState(() {
            AppConfig.enableRightAndLeftMessageAlignmentOnWeb = value;
          });
        })
        .catchError((Object e, StackTrace s) {
          Logs().w('MatrixState::_preloadMessageAlignmentSetting: error', e, s);
        });
  }

  Future<void> initSettings() async {
    try {
      await Future.wait([
        store.getItem(SettingKeys.wallpaper).then((final path) async {
          if (path == null) return;
          final file = File(path);
          if (await file.exists()) {
            wallpaper = file;
          }
        }),
        store
            .getItem(SettingKeys.fontSizeFactor)
            .then(
              (value) => AppConfig.fontSizeFactor =
                  double.tryParse(value ?? '') ?? AppConfig.fontSizeFactor,
            ),
        store
            .getItem(SettingKeys.bubbleSizeFactor)
            .then(
              (value) => AppConfig.bubbleSizeFactor =
                  double.tryParse(value ?? '') ?? AppConfig.bubbleSizeFactor,
            ),
        store
            .getItemBool(SettingKeys.renderHtml, AppConfig.renderHtml)
            .then((value) => AppConfig.renderHtml = value),
        store
            .getItemBool(
              SettingKeys.hideUnknownEvents,
              AppConfig.hideUnknownEvents,
            )
            .then((value) => AppConfig.hideUnknownEvents = value),
        store
            .getItemBool(
              SettingKeys.showDirectChatsInSpaces,
              AppConfig.showDirectChatsInSpaces,
            )
            .then((value) => AppConfig.showDirectChatsInSpaces = value),
        store
            .getItemBool(
              SettingKeys.separateChatTypes,
              AppConfig.separateChatTypes,
            )
            .then((value) => AppConfig.separateChatTypes = value),
        store
            .getItemBool(SettingKeys.autoplayImages, AppConfig.autoplayImages)
            .then((value) => AppConfig.autoplayImages = value),
        store
            .getItemBool(SettingKeys.gifAutoplay, AppConfig.gifAutoplay)
            .then((value) => AppConfig.gifAutoplay = value),
        store
            .getItemBool(
              SettingKeys.experimentalVoip,
              AppConfig.experimentalVoip,
            )
            .then((value) => AppConfig.experimentalVoip = value),
      ]);
    } catch (e, s) {
      Logs().wtf('MatrixState::initSettings: error', e, s);
    } finally {
      initSettingsCompleter.complete();
    }
  }

  void cancelAudioPlayerAutoDispose() {
    _audioPlayerStateSubscription?.cancel();
    _audioPlayerStateSubscription = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (PlatformInfos.isWeb) {
      html.window.removeEventListener('focus', onWindowFocus);
      html.window.removeEventListener('blur', onWindowBlur);
      html.document.removeEventListener('visibilitychange', onVisibilityChange);
      FocusManager.instance.removeListener(_onFocusManagerChange);
    }
    intentFileStreamSubscription?.cancel();
    intentUriStreamSubscription?.cancel();
    unawaited(_subscriptions.cancelAll());
    _logoutRemovals.dispose();
    _pushRemovals.dispose();
    onClientLoginStateChanged.close();
    // A provider cannot be written while the tree is being finalized.
    final switchEffects = _switchEffects;
    final pushController = _pushController;
    final pushTeardown = _pushTeardown;
    unawaited(
      Future.microtask(() {
        switchEffects.clear(this);
        pushController.clearTeardown(pushTeardown);
      }),
    );
    _httpClientOwner?.httpClient.close();
    onFocusSub?.cancel();
    onBlurSub?.cancel();
    backgroundPush?.clearingPushTimer?.cancel();
    showToMBootstrap.dispose();
    linuxNotifications?.close();
    showQrCodeDownload.dispose();
    _audioPlayerStateSubscription?.cancel();
    audioPlayer.dispose();
    voiceMessageEvent.dispose();
    _presenceSubscription?.cancel();
    onLatestPresenceChanged.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Provider(create: (_) => this, child: widget.child);
  }

  @override
  MatrixState get matrixState => this;
}

class FixedThreepidCreds extends ThreepidCreds {
  FixedThreepidCreds({
    required super.sid,
    required super.clientSecret,
    super.idServer,
    super.idAccessToken,
  });

  @override
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['sid'] = sid;
    data['client_secret'] = clientSecret;
    if (idServer != null) data['id_server'] = idServer;
    if (idAccessToken != null) data['id_access_token'] = idAccessToken;
    return data;
  }
}

extension HomeserverSummaryConversion
    on
        Future<
          (
            DiscoveryInformation?,
            GetVersionsResponse,
            List<LoginFlow>,
            GetAuthMetadataResponse?,
          )
        > {
  Future<HomeserverSummary> toHomeserverSummary() async {
    try {
      final result = await this;
      return HomeserverSummary(
        discoveryInformation: result.$1,
        versions: result.$2,
        loginFlows: result.$3,
      );
    } catch (e, s) {
      Logs().wtf('HomeserverSummaryConversion::toHomeserverSummary', e, s);
      rethrow;
    }
  }
}

/// The push state `MatrixState` owns, given to `PushRemovalsController`.
class _MatrixPushTeardown implements PushTeardown {
  _MatrixPushTeardown(this._state);

  final MatrixState _state;

  @override
  Future<void> removePush(Client target) => _state._removePush(target);

  @override
  bool get isPushReady =>
      !PlatformInfos.isMobile || (_state.backgroundPush?.hasPushToken ?? false);

  @override
  void report(Object error, StackTrace stackTrace, String what) =>
      _state._report(error, stackTrace, what);
}
