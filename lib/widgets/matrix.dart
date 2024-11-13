import 'dart:async';
import 'dart:io';
import 'package:fluffychat/domain/contact_manager/contacts_manager.dart';
import 'package:fluffychat/presentation/mixins/init_config_mixin.dart';
import 'package:fluffychat/presentation/model/client_login_state_event.dart';
import 'package:fluffychat/widgets/layouts/agruments/logout_body_args.dart';
import 'package:universal_html/html.dart' as html hide File;

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:collection/collection.dart';
import 'package:desktop_notifications/desktop_notifications.dart';
import 'package:equatable/equatable.dart';
import 'package:fluffychat/data/hive/hive_collection_tom_database.dart';
import 'package:fluffychat/data/network/interceptor/authorization_interceptor.dart';
import 'package:fluffychat/data/network/interceptor/dynamic_url_interceptor.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/di/global/network_di.dart';
import 'package:fluffychat/domain/model/extensions/homeserver_summary_extensions.dart';
import 'package:fluffychat/domain/model/tom_configurations.dart';
import 'package:fluffychat/domain/model/tom_server_information.dart';
import 'package:fluffychat/domain/repository/multiple_account/multiple_account_repository.dart';
import 'package:fluffychat/domain/repository/tom_configurations_repository.dart';
import 'package:fluffychat/pages/chat_list/receive_sharing_intent_mixin.dart';
import 'package:fluffychat/utils/client_manager.dart';
import 'package:fluffychat/utils/localized_exception_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/utils/uia_request_manager.dart';
import 'package:fluffychat/utils/url_launcher.dart';
import 'package:fluffychat/utils/voip_plugin.dart';
import 'package:fluffychat/widgets/set_active_client_state.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_lock/flutter_app_lock.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:matrix/encryption.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;

import '../config/app_config.dart';
import '../config/setting_keys.dart';
import '../pages/key_verification/key_verification_dialog.dart';
import '../utils/account_bundles.dart';
import '../utils/background_push.dart';
import '../utils/famedlysdk_store.dart';
import 'local_notifications_extension.dart';

class Matrix extends StatefulWidget {
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
}

class MatrixState extends State<Matrix>
    with WidgetsBindingObserver, ReceiveSharingIntentMixin, InitConfigMixin {
  final tomConfigurationRepository = getIt.get<ToMConfigurationsRepository>();

  final _contactsManager = getIt.get<ContactsManager>();

  int _activeClient = -1;
  String? activeBundle;
  Store store = Store();
  HomeserverSummary? loginHomeserverSummary;
  String? _authUrl;
  XFile? loginAvatar;
  String? loginUsername;
  LoginType? loginType;
  bool? loginRegistrationSupported;

  bool waitForFirstSync = false;

  bool firstLogin = false;

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
      _activeClient >= 0 && _activeClient < widget.clients.length;

  String? get authUrl => _authUrl;

  Client get client {
    if (widget.clients.isEmpty) {
      widget.clients.add(getLoginClient());
    }
    if (!isValidActiveClient) {
      return currentBundle!.first!;
    }
    return widget.clients[_activeClient];
  }

  // TODO: 28Dec2023 Disable until support voip
  bool get webrtcIsSupported => false;

  VoipPlugin? voipPlugin;

  bool get isMultiAccount => widget.clients.length > 1;

  int getClientIndexByMatrixId(String matrixId) =>
      widget.clients.indexWhere((client) => client.userID == matrixId);

  late String currentClientSecret;
  RequestTokenResponse? currentThreepidCreds;

  Future<SetActiveClientState> setActiveClient(Client? newClient) async {
    final index = widget.clients.indexWhere(
      (client) => newClient != null && client.userID == newClient.userID,
    );
    if (index != -1) {
      _activeClient = index;
      // TODO: Multi-client VoiP support
      createVoipPlugin();
      await _setUpToMServicesWhenChangingActiveClient(newClient);
      await _storePersistActiveAccount(newClient!);
      return SetActiveClientState.success;
    } else {
      Logs().w('Tried to set an unknown client ${newClient!.userID} as active');
      return SetActiveClientState.unknownClient;
    }
  }

  List<Client?>? get currentBundle {
    if (!hasComplexBundles) {
      return List.from(widget.clients);
    }
    final bundles = accountBundles;
    if (bundles.containsKey(activeBundle)) {
      return bundles[activeBundle];
    }
    return bundles.values.first;
  }

  Map<String?, List<Client?>> get accountBundles {
    final resBundles = <String?, List<_AccountBundleWithClient>>{};
    for (var i = 0; i < widget.clients.length; i++) {
      final bundles = widget.clients[i].accountBundles;
      for (final bundle in bundles) {
        if (bundle.name == null) {
          continue;
        }
        resBundles[bundle.name] ??= [];
        resBundles[bundle.name]!.add(
          _AccountBundleWithClient(
            client: widget.clients[i],
            bundle: bundle,
          ),
        );
      }
    }
    for (final b in resBundles.values) {
      b.sort(
        (a, b) => a.bundle!.priority == null
            ? 1
            : b.bundle!.priority == null
                ? -1
                : a.bundle!.priority!.compareTo(b.bundle!.priority!),
      );
    }
    return resBundles
        .map((k, v) => MapEntry(k, v.map((vv) => vv.client).toList()));
  }

  bool get hasComplexBundles => accountBundles.values.any((v) => v.length > 1);

  Client? _loginClientCandidate;

  Client getLoginClient() {
    if (widget.clients.isNotEmpty && !client.isLogged()) {
      return client;
    }
    final candidate = _loginClientCandidate ??= ClientManager.createClient(
      '${AppConfig.applicationName}-${DateTime.now().millisecondsSinceEpoch}',
    )..onLoginStateChanged
        .stream
        .where((l) => l == LoginState.loggedIn)
        .first
        .then((state) => _handleAddAnotherAccount(state));
    return candidate;
  }

  Client? getClientByUserId(String userId) =>
      widget.clients.firstWhereOrNull((c) => c.userID == userId);

  Client? getClientByName(String name) =>
      widget.clients.firstWhereOrNull((c) => c.clientName == name);

  Map<String, dynamic>? get shareContent => _shareContent;

  set shareContent(Map<String, dynamic>? content) {
    _shareContent = content;
    onShareContentChanged.add(_shareContent);
  }

  Map<String, dynamic>? _shareContent;

  List<Map<String, dynamic>?> get shareContentList => _shareContentList ?? [];

  set shareContentList(List<Map<String, dynamic>?>? content) {
    _shareContentList = content;
    onShareContentChanged.add(_shareContent);
  }

  List<Map<String, dynamic>?>? _shareContentList;

  final StreamController<Map<String, dynamic>?> onShareContentChanged =
      StreamController.broadcast();

  File? wallpaper;

  void _initWithStore() async {
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

  final onRoomKeyRequestSub = <String, StreamSubscription>{};
  final onKeyVerificationRequestSub = <String, StreamSubscription>{};
  final onNotification = <String, StreamSubscription>{};
  final onLoginStateChanged = <String, StreamSubscription<LoginState>>{};
  final onUiaRequest = <String, StreamSubscription<UiaRequest>>{};
  final StreamController<ClientLoginStateEvent> onClientLoginStateChanged =
      StreamController.broadcast();
  StreamSubscription<html.Event>? onFocusSub;
  StreamSubscription<html.Event>? onBlurSub;

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

  final linuxNotifications =
      PlatformInfos.isLinux ? NotificationsClient() : null;
  final Map<String, int> linuxNotificationIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      WidgetsBinding.instance.addObserver(this);
      if (PlatformInfos.isWeb) {
        html.window.addEventListener('focus', onWindowFocus);
        html.window.addEventListener('blur', onWindowBlur);
      }
      initMatrix();
      initReceiveSharingIntent();
      if (PlatformInfos.isWeb) {
        initConfigWeb().then((_) => initSettings());
      } else {
        initConfigMobile().then((_) => initSettings());
      }
      listenShowToMBootstrap();
    });
  }

  void initLoadingDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LoadingDialog.defaultOnError =
          (e) => (e as Object?)!.toLocalizedString(context);
    });
  }

  void _registerSubs(String name) async {
    final currentClient = getClientByName(name);
    if (currentClient == null) {
      Logs().w(
        'Attempted to register subscriptions for non-existing client $name',
      );
      return;
    }
    if (PlatformInfos.isMobile) {
      await HiveCollectionToMDatabase.databaseBuilder();
    }
    onRoomKeyRequestSub[name] ??= currentClient.onRoomKeyRequest.stream
        .listen((RoomKeyRequest request) async {
      if (widget.clients.any(
        ((cl) =>
            cl.userID == request.requestingDevice.userId &&
            cl.identityKey == request.requestingDevice.curve25519Key),
      )) {
        Logs().i(
          '[Key Request] Request is from one of our own clients, forwarding the key...',
        );
        await request.forwardKey();
      }
    });
    onKeyVerificationRequestSub[name] ??= currentClient
        .onKeyVerificationRequest.stream
        .listen((KeyVerification request) async {
      var hidPopup = false;
      request.onUpdate = () {
        if (!hidPopup &&
            {KeyVerificationState.done, KeyVerificationState.error}
                .contains(request.state)) {
          Navigator.of(context).pop('dialog');
        }
        hidPopup = true;
      };
      request.onUpdate = null;
      hidPopup = true;
      await KeyVerificationDialog(request: request).show(context);
    });
    onLoginStateChanged[name] ??= currentClient.onLoginStateChanged.stream
        .listen((state) => _listenLoginStateChanged(state, currentClient));
    onUiaRequest[name] ??=
        currentClient.onUiaRequest.stream.listen(uiaRequestHandler);
    if (PlatformInfos.isWeb || PlatformInfos.isLinux) {
      currentClient.onSync.stream.first.then((s) {
        html.Notification.requestPermission();
        onNotification[name] ??= currentClient.onEvent.stream
            .where(
              (e) =>
                  e.type == EventUpdateType.timeline &&
                  [EventTypes.Message, EventTypes.Sticker, EventTypes.Encrypted]
                      .contains(e.content['type']) &&
                  e.content['sender'] != currentClient.userID,
            )
            .listen(showLocalNotification);
      });
    }
  }

  void _listenLoginStateChanged(LoginState state, Client client) async {
    final loggedInWithMultipleClients = widget.clients.length > 1;
    if (loggedInWithMultipleClients && state != LoginState.loggedIn) {
      _handleLogoutWithMultipleAccount(state, client);
    } else {
      if (state == LoginState.loggedIn) {
        Logs().v('[MATRIX]:_listenLoginStateChanged:: First Log in successful');
        _handleFirstLoggedIn(client, state);
      } else {
        Logs().v('[MATRIX]:_listenLoginStateChanged:: Last Log out successful');
        await _handleLastLogout();
      }
    }
  }

  void _handleLogoutWithMultipleAccount(
    LoginState state,
    Client currentClient,
  ) async {
    await _cancelSubs(currentClient.clientName);
    widget.clients.remove(currentClient);
    await ClientManager.removeClientNameFromStore(currentClient.clientName);
    matrixState.reSyncContacts();
    TwakeSnackBar.show(
      TwakeApp.routerKey.currentContext!,
      L10n.of(context)!.oneClientLoggedOut,
    );
    final result = await setActiveClient(widget.clients.first);
    Logs().v(
      '[MATRIX]:_handleLogoutWithMultipleAccount:: Log out Client ${currentClient.clientName} successful',
    );
    if (state != LoginState.loggedIn && result.isSuccess) {
      TwakeApp.router.go(
        '/rooms',
        extra: LogoutBodyArgs(
          newActiveClient: widget.clients.first,
        ),
      );
    }
  }

  Future<void> _handleFirstLoggedIn(
    Client newActiveClient,
    LoginState loginState,
  ) async {
    waitForFirstSync = false;
    markFirstLogin();
    await setUpToMServicesInLogin(newActiveClient);
    await _storePersistActiveAccount(newActiveClient);
    matrixState.reSyncContacts();
    onClientLoginStateChanged.add(
      ClientLoginStateEvent(
        client: client,
        loginState: loginState,
        multipleAccountLoginType: MultipleAccountLoginType.firstLoggedIn,
      ),
    );
  }

  Future<void> _handleAddAnotherAccount(LoginState loginState) async {
    Logs().d(
      'MatrixState::_handleAddAnotherAccount() - Add another account successful',
    );
    Logs().d(
      'MatrixState::_handleAddAnotherAccount() - New Client ${_loginClientCandidate!.clientName}',
    );
    if (!widget.clients.contains(_loginClientCandidate)) {
      widget.clients.add(_loginClientCandidate!);
    }
    ClientManager.addClientNameToStore(_loginClientCandidate!.clientName);
    Logs().d('MatrixState::_handleAddAnotherAccount() - Registering subs');
    _registerSubs(_loginClientCandidate!.clientName);
    final activeClient = getClientByName(
      _loginClientCandidate!.clientName,
    );
    if (activeClient == null) return;
    waitForFirstSync = false;
    await setUpToMServicesInLogin(activeClient);
    final result = await setActiveClient(activeClient);
    matrixState.reSyncContacts();
    if (result.isSuccess) {
      onClientLoginStateChanged.add(
        ClientLoginStateEvent(
          client: client,
          loginState: loginState,
          multipleAccountLoginType:
              MultipleAccountLoginType.otherAccountLoggedIn,
        ),
      );
      _loginClientCandidate = null;
    }
  }

  Future<void> _deletePersistActiveAccount() async {
    try {
      final multipleAccountRepository = getIt.get<MultipleAccountRepository>();
      await multipleAccountRepository.deletePersistActiveAccount();
      Logs().d(
        'MatrixState::_handleLogoutWithMultipleAccount: Delete persist active account success',
      );
    } catch (e) {
      Logs().e(
        'MatrixState::_handleLogoutWithMultipleAccount: Error - $e',
      );
    }
  }

  Future<void> _cancelSubs(String name) async {
    await onRoomKeyRequestSub[name]?.cancel();
    onRoomKeyRequestSub.remove(name);
    await onKeyVerificationRequestSub[name]?.cancel();
    onKeyVerificationRequestSub.remove(name);
    await onLoginStateChanged[name]?.cancel();
    onLoginStateChanged.remove(name);
    await onNotification[name]?.cancel();
    onNotification.remove(name);
  }

  void initMatrix() {
    // Display the app lock
    if (PlatformInfos.isMobile) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ([TargetPlatform.linux].contains(Theme.of(context).platform)
                ? SharedPreferences.getInstance()
                    .then((prefs) => prefs.getString(SettingKeys.appLockKey))
                : const FlutterSecureStorage()
                    .read(key: SettingKeys.appLockKey))
            .then((lock) {
          if (lock?.isNotEmpty ?? false) {
            AppLock.of(context)!.enable();
            AppLock.of(context)!.showLockScreen();
          }
        });
      });
    }

    _initWithStore();

    for (final c in widget.clients) {
      Logs().d('MatrixState::initMatrix: ${c.clientName} calling registerSubs');
      _registerSubs(c.clientName);
    }

    _retrieveLocalToMConfiguration();

    if (kIsWeb) {
      onFocusSub = html.window.onFocus.listen((_) => webHasFocus = true);
      onBlurSub = html.window.onBlur.listen((_) => webHasFocus = false);
    }

    if (PlatformInfos.isMobile) {
      backgroundPush = BackgroundPush(
        this,
        client,
        onFcmError: (errorMsg, {Uri? link}) async {
          final result = await showOkCancelAlertDialog(
            barrierDismissible: true,
            context: context,
            title: L10n.of(context)!.oopsSomethingWentWrong,
            message: errorMsg,
            okLabel:
                link == null ? L10n.of(context)!.ok : L10n.of(context)!.help,
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
    }

    createVoipPlugin();
  }

  void createVoipPlugin() async {
    if (await store.getItemBool(SettingKeys.experimentalVoip) == false) {
      voipPlugin = null;
      return;
    }
    voipPlugin = webrtcIsSupported ? VoipPlugin(client) : null;
  }

  Future<ToMConfigurations?> getTomConfigurations(String userID) async {
    try {
      final tomConfigurationRepository =
          getIt.get<ToMConfigurationsRepository>();
      final toMConfigurations =
          await tomConfigurationRepository.getTomConfigurations(userID);
      return toMConfigurations;
    } catch (e) {
      Logs().e('MatrixState::_getTomConfigurations: $e');
    }
    return null;
  }

  void _retrieveLocalToMConfiguration() async {
    if (client.userID == null) return;
    try {
      final toMConfigurations = await getTomConfigurations(client.userID!);
      if (toMConfigurations == null) {
        _setupAuthUrl();
        return;
      }
      setUpToMServices(
        toMConfigurations.tomServerInformation,
        toMConfigurations.identityServerInformation,
      );
      _setupAuthUrl(url: toMConfigurations.authUrl);
      loginType = toMConfigurations.loginType;
    } catch (e) {
      Logs().e('MatrixState::_retrieveToMConfiguration: $e');
    }
  }

  void setUpToMServices(
    ToMServerInformation tomServer,
    IdentityServerInformation? identityServer,
  ) {
    Logs().d(
      'MatrixState::setUpToMServices: $tomServer, ${identityServer?.baseUrl}',
    );
    _setUpToMServer(tomServer);
    if (identityServer != null) {
      _setUpIdentityServer(identityServer);
    }
    setUpAuthorization(client);
    if (client.homeserver != null) {
      _setUpHomeServer(client.homeserver!);
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
        loginHomeserverSummary?.discoveryInformation?.mHomeserver;
    _setupAuthUrl();
    if (identityServer != null) {
      _setUpIdentityServer(identityServer);
    }
    if (homeServer != null) {
      _setUpHomeServer(homeServer.baseUrl);
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
    identityServerUrlInterceptor
        .changeBaseUrl(identityServer.baseUrl.toString());
  }

  Future<void> _storeToMConfiguration(
    Client client,
    ToMConfigurations config,
  ) async {
    try {
      Logs().e(
        'Matrix::_storeToMConfiguration: clientName - ${client.clientName}',
      );
      Logs().e(
        'Matrix::_storeToMConfiguration: userId - ${client.userID}',
      );
      if (client.userID == null) return;
      final ToMConfigurationsRepository configurationRepository =
          getIt.get<ToMConfigurationsRepository>();
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

  Future<void> _setUpToMServicesWhenChangingActiveClient(Client? client) async {
    Logs().d(
      'Matrix::_checkHomeserverExists: Old twakeSupported - $twakeSupported',
    );
    if (client == null && client?.userID == null) return;
    try {
      final toMConfigurations = await getTomConfigurations(client!.userID!);
      Logs().d(
        'Matrix::_checkHomeserverExists: toMConfigurations - $toMConfigurations',
      );
      if (toMConfigurations == null) {
        _setUpToMServer(null);
        _setupAuthUrl();
        setUpAuthorization(client);
      } else {
        _setupAuthUrl(url: toMConfigurations.authUrl);
        setUpToMServices(
          toMConfigurations.tomServerInformation,
          toMConfigurations.identityServerInformation,
        );
      }
    } catch (e) {
      _setUpToMServer(null);
      _setupAuthUrl();
      setUpAuthorization(client!);
      Logs().e('Matrix::_checkHomeserverExists: error - $e');
    }
    Logs().d(
      'Matrix::_checkHomeserverExists: New twakeSupported - $twakeSupported',
    );
  }

  Future<void> retrievePersistedActiveClient() async {
    try {
      final multipleAccountRepository = getIt.get<MultipleAccountRepository>();
      final persistActiveAccount =
          await multipleAccountRepository.getPersistActiveAccount();
      if (persistActiveAccount == null) {
        await _storePersistActiveAccount(client);
        return;
      } else {
        final newActiveClient = getClientByUserId(persistActiveAccount);
        if (newActiveClient != null) {
          await setActiveClient(newActiveClient);
        }
      }
    } catch (e) {
      Logs().e(
        'Matrix::_retrievePersistedActiveAccount(): Error - $e',
      );
    }
  }

  Future<void> _storePersistActiveAccount(Client newClient) async {
    if (newClient.userID == null) return;
    try {
      Logs().d(
        'Matrix::_storePersistActiveAccount: clientName - ${newClient.clientName}',
      );
      Logs().d(
        'Matrix::_storePersistActiveAccount: userId - ${newClient.userID}',
      );
      final MultipleAccountRepository multipleAccountRepository =
          getIt.get<MultipleAccountRepository>();
      await multipleAccountRepository.storePersistActiveAccount(
        newClient.userID!,
      );
    } catch (e) {
      Logs().e(
        'Matrix::_storePersistActiveAccount(): Error - $e',
      );
    }
  }

  void onWindowFocus(html.Event e) {
    didChangeAppLifecycleState(AppLifecycleState.resumed);
  }

  void onWindowBlur(html.Event e) {
    didChangeAppLifecycleState(AppLifecycleState.paused);
  }

  Future<void> _setupAuthUrl({
    String? url,
  }) async {
    if (url != null) {
      Logs().e(
        'Matrix::_setupAuthUrl: newAuthUrl - $url',
      );
      _authUrl = url;
    } else {
      final newAuthUrl = loginHomeserverSummary?.discoveryInformation
          ?.additionalProperties["m.authentication"]?["issuer"];
      Logs().e(
        'Matrix::_setupAuthUrl: newAuthUrl - $newAuthUrl',
      );
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

  Future<void> _handleLastLogout() async {
    matrixState.reSyncContacts();
    if (PlatformInfos.isMobile) {
      await _deletePersistActiveAccount();
      TwakeApp.router.go('/home/twakeWelcome');
    } else {
      TwakeApp.router.go('/home', extra: true);
    }
    await _deleteAllTomConfigurations();
  }

  Future<void> reSyncContacts() async {
    _contactsManager.reSyncContacts();
  }

  void markFirstLogin() {
    firstLogin = true;
  }

  void resetFirstLogin() {
    firstLogin = false;
    handleShowQrCodeDownload(firstLogin);
  }

  void handleShowQrCodeDownload(bool show) {
    showQrCodeDownload.value = show;
  }

  void listenShowToMBootstrap() {
    showToMBootstrap.addListener(() {
      handleShowQrCodeDownload(firstLogin);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    Logs().i('didChangeAppLifecycleState: AppLifecycleState = $state');
    Logs().i('didChangeAppLifecycleState: currentTime: ${DateTime.now()}');
    final foreground = state != AppLifecycleState.detached &&
        state != AppLifecycleState.paused;
    client.backgroundSync = foreground;
    client.syncPresence = foreground ? null : PresenceType.unavailable;
    client.sync(setPresence: client.syncPresence);
    client.requestHistoryOnLimitedTimeline = !foreground;
    backgroundPush?.clearAllNotifications();
  }

  void initSettings() {
    store.getItem(SettingKeys.wallpaper).then((final path) async {
      if (path == null) return;
      final file = File(path);
      if (await file.exists()) {
        wallpaper = file;
      }
    });
    store.getItem(SettingKeys.fontSizeFactor).then(
          (value) => AppConfig.fontSizeFactor =
              double.tryParse(value ?? '') ?? AppConfig.fontSizeFactor,
        );
    store.getItem(SettingKeys.bubbleSizeFactor).then(
          (value) => AppConfig.bubbleSizeFactor =
              double.tryParse(value ?? '') ?? AppConfig.bubbleSizeFactor,
        );
    store
        .getItemBool(SettingKeys.renderHtml, AppConfig.renderHtml)
        .then((value) => AppConfig.renderHtml = value);
    store
        .getItemBool(
          SettingKeys.hideRedactedEvents,
          AppConfig.hideRedactedEvents,
        )
        .then((value) => AppConfig.hideRedactedEvents = value);
    store
        .getItemBool(SettingKeys.hideUnknownEvents, AppConfig.hideUnknownEvents)
        .then((value) => AppConfig.hideUnknownEvents = value);
    store
        .getItemBool(
          SettingKeys.showDirectChatsInSpaces,
          AppConfig.showDirectChatsInSpaces,
        )
        .then((value) => AppConfig.showDirectChatsInSpaces = value);
    store
        .getItemBool(SettingKeys.separateChatTypes, AppConfig.separateChatTypes)
        .then((value) => AppConfig.separateChatTypes = value);
    store
        .getItemBool(SettingKeys.autoplayImages, AppConfig.autoplayImages)
        .then((value) => AppConfig.autoplayImages = value);
    store
        .getItemBool(SettingKeys.experimentalVoip, AppConfig.experimentalVoip)
        .then((value) => AppConfig.experimentalVoip = value);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (PlatformInfos.isWeb) {
      html.window.removeEventListener('focus', onWindowFocus);
      html.window.removeEventListener('blur', onWindowBlur);
    }
    intentDataStreamSubscription?.cancel();
    intentFileStreamSubscription?.cancel();
    intentUriStreamSubscription?.cancel();
    onRoomKeyRequestSub.values.map((s) => s.cancel());
    onKeyVerificationRequestSub.values.map((s) => s.cancel());
    onLoginStateChanged.values.map((s) => s.cancel());
    onNotification.values.map((s) => s.cancel());
    onClientLoginStateChanged.close();
    client.httpClient.close();
    onFocusSub?.cancel();
    onBlurSub?.cancel();
    backgroundPush?.onRoomSync?.cancel();
    showToMBootstrap.dispose();
    linuxNotifications?.close();
    showQrCodeDownload.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (_) => this,
      child: widget.child,
    );
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

class _AccountBundleWithClient extends Equatable {
  final Client? client;
  final AccountBundle? bundle;

  const _AccountBundleWithClient({this.client, this.bundle});

  @override
  List<Object?> get props => [client, bundle];
}
