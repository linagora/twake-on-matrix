import 'dart:async';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/repository/tom_configurations_repository.dart';
import 'package:fluffychat/event/twake_inapp_event_types.dart';
import 'package:fluffychat/pages/bootstrap/bootstrap_dialog.dart';
import 'package:fluffychat/presentation/mixins/connect_page_mixin.dart';
import 'package:fluffychat/presentation/enum/settings/settings_enum.dart';
import 'package:fluffychat/presentation/extensions/client_extension.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/url_launcher.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:flutter/material.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

import 'settings_view.dart';

class Settings extends StatefulWidget {
  final Widget? bottomNavigationBar;

  const Settings({
    super.key,
    this.bottomNavigationBar,
  });

  @override
  SettingsController createState() => SettingsController();
}

class SettingsController extends State<Settings> with ConnectPageMixin {
  final ValueNotifier<Uri?> avatarUriNotifier = ValueNotifier(Uri());
  final ValueNotifier<String?> displayNameNotifier = ValueNotifier('');

  final tomConfigurationRepository = getIt.get<ToMConfigurationsRepository>();

  StreamSubscription? onAccountDataSubscription;

  final List<SettingEnum> getListSettingItem = [
    SettingEnum.chatSettings,
    SettingEnum.privacyAndSecurity,
    SettingEnum.notificationAndSounds,
    SettingEnum.appLanguage,
    SettingEnum.devices,
    SettingEnum.help,
    SettingEnum.about,
    SettingEnum.logout,
  ];

  final ValueNotifier<SettingEnum?> optionsSelectNotifier = ValueNotifier(null);

  final ValueNotifier<bool?> showChatBackupSwitch = ValueNotifier(null);

  MatrixState get matrix => Matrix.of(context);

  String get displayName =>
      displayNameNotifier.value ??
      client.mxid(context).localpart ??
      client.mxid(context);

  bool optionSelected(SettingEnum settingEnum) =>
      settingEnum == optionsSelectNotifier.value;

  void logoutAction() async {
    final noBackup = showChatBackupSwitch.value == true;
    final twakeContext = TwakeApp.routerKey.currentContext;
    if (twakeContext == null) {
      Logs().e(
        'SettingsController()::logoutAction - Twake context is null',
      );
    }
    if (await showOkCancelAlertDialog(
          useRootNavigator: false,
          context: twakeContext!,
          title: L10n.of(context)!.areYouSureYouWantToLogout,
          message: L10n.of(context)!.noBackupWarning,
          isDestructiveAction: noBackup,
          okLabel: L10n.of(context)!.logout,
          cancelLabel: L10n.of(context)!.cancel,
        ) ==
        OkCancelResult.cancel) {
      return;
    }
    if (PlatformInfos.isMobile) {
      await _logoutActionsOnMobile();
    } else {
      await _logoutActions();
    }
  }

  Future<void> _logoutActionsOnMobile() async {
    try {
      await tryLogoutSso(context);
    } catch (e) {
      Logs().e('SettingsController()::_logoutActionsOnMobile - error: $e');
      return;
    }
    await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () async {
        try {
          if (matrix.backgroundPush != null) {
            await matrix.backgroundPush!.removeCurrentPusher();
          }
          await Future.wait([
            matrix.client.logout(),
            _deleteTomConfigurations(matrix.client),
          ]);
        } catch (e) {
          Logs().e('SettingsController()::_logoutActionsOnMobile - error: $e');
        }
      },
    );
  }

  Future<void> _logoutActions() async {
    await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () async {
        try {
          if (matrix.backgroundPush != null) {
            await matrix.backgroundPush!.removeCurrentPusher();
          }
          await Future.wait([
            matrix.client.logout(),
            _deleteTomConfigurations(matrix.client),
          ]);
        } catch (e) {
          Logs().e('SettingsController()::_logoutActions - error: $e');
        } finally {
          try {
            await tryLogoutSso(context);
          } catch (e) {
            Logs().e('SettingsController()::_logoutActions - error: $e');
            return;
          }
        }
      },
    );
  }

  Client get client => Matrix.of(context).client;

  void _getCurrentProfile(Client client) async {
    final profile = await client.getProfileFromUserId(
      client.userID!,
      getFromRooms: false,
    );
    Logs().d(
      'Settings::_getCurrentProfile() - currentProfile: $profile',
    );
    avatarUriNotifier.value = profile.avatarUrl;
    displayNameNotifier.value = profile.displayName;
  }

  void checkBootstrap() async {
    if (!client.encryptionEnabled) return;
    await client.accountDataLoading;
    await client.userDeviceKeysLoading;
    if (client.prevBatch == null) {
      await client.onSync.stream.first;
    }
    final crossSigning =
        await client.encryption?.crossSigning.isCached() ?? false;
    Logs().d(
      "SettingsController::checkBootstrap() - crossSigning: $crossSigning",
    );
    final needsBootstrap =
        await client.encryption?.keyManager.isCached() == false ||
            client.encryption?.crossSigning.enabled == false ||
            crossSigning == false;
    Logs().d(
      "SettingsController::checkBootstrap() - needsBootstrap: $needsBootstrap",
    );
    final isUnknownSession = client.isUnknownSession;
    Logs().d(
      "SettingsController::checkBootstrap() - isUnknownSession: $isUnknownSession",
    );
    showChatBackupSwitch.value = needsBootstrap || isUnknownSession;
    Logs().d(
      "SettingsController::checkBootstrap() - showChatBackupSwitch: ${showChatBackupSwitch.value}",
    );
  }

  void firstRunBootstrapAction([_]) async {
    if (showChatBackupSwitch.value != true) {
      showOkAlertDialog(
        context: context,
        title: L10n.of(context)!.chatBackup,
        message: L10n.of(context)!.onlineKeyBackupEnabled,
        okLabel: L10n.of(context)!.close,
      );
      return;
    }
    await BootstrapDialog(
      client: Matrix.of(context).client,
    ).show();
    checkBootstrap();
  }

  void goToSettingsProfile() async {
    optionsSelectNotifier.value = SettingEnum.profile;
    final result = await context.push('/rooms/profile');
    if (result == null) {
      optionsSelectNotifier.value = null;
    }
  }

  void onClickToSettingsItem(SettingEnum settingEnum) async {
    optionsSelectNotifier.value = settingEnum;
    switch (settingEnum) {
      case SettingEnum.chatSettings:
        final result = await context.push('/rooms/chat');
        if (result == null) {
          optionsSelectNotifier.value = null;
        }
        break;
      case SettingEnum.privacyAndSecurity:
        final result = await context.push('/rooms/security');
        if (result == null) {
          optionsSelectNotifier.value = null;
        }
        break;
      case SettingEnum.notificationAndSounds:
        final result = await context.push('/rooms/notifications');
        if (result == null) {
          optionsSelectNotifier.value = null;
        }
        break;
      case SettingEnum.chatFolders:
        break;
      case SettingEnum.appLanguage:
        final result = await context.push('/rooms/appLanguage');
        if (result == null) {
          optionsSelectNotifier.value = null;
        }
        break;
      case SettingEnum.devices:
        final result = await context.push('/rooms/devices');
        if (result == null) {
          optionsSelectNotifier.value = null;
        }
        break;
      case SettingEnum.help:
        UrlLauncher(
          context,
          url: AppConfig.supportUrl,
        ).openUrlInAppBrowser();
        break;
      case SettingEnum.about:
        PlatformInfos.showAboutDialogFullScreen();
      case SettingEnum.logout:
        logoutAction();
        break;
      default:
        break;
    }
  }

  void _handleOnAccountDataSubscription() {
    onAccountDataSubscription = client.onAccountData.stream.listen((event) {
      if (event.type == TwakeInappEventTypes.uploadAvatarEvent) {
        final newProfile = Profile.fromJson(event.content);
        if (newProfile.avatarUrl != avatarUriNotifier.value) {
          avatarUriNotifier.value = newProfile.avatarUrl;
        }
        if (newProfile.displayName != displayNameNotifier.value) {
          displayNameNotifier.value = newProfile.displayName;
        }
      }
    });
  }

  Future<void> _deleteTomConfigurations(Client currentClient) async {
    try {
      Logs().d(
        'SettingsController::_deleteTomConfigurations - Client ID: ${currentClient.userID}',
      );
      if (matrix.twakeSupported) {
        await tomConfigurationRepository
            .deleteTomConfigurations(currentClient.userID!);
      }
      Logs().d(
        'SettingsController::_deleteTomConfigurations - Success',
      );
    } catch (e) {
      Logs().e(
        'SettingsController::_deleteTomConfigurations - error: $e',
      );
    }
  }

  @override
  void initState() {
    _getCurrentProfile(client);
    _handleOnAccountDataSubscription();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkBootstrap();
    });
    super.initState();
  }

  @override
  void didUpdateWidget(Settings oldWidget) {
    if (oldWidget != widget) {
      _getCurrentProfile(client);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    onAccountDataSubscription?.cancel();
    if (avatarUriNotifier.value != null) {
      avatarUriNotifier.dispose();
    }

    if (displayNameNotifier.value != null) {
      displayNameNotifier.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsView(
      this,
      bottomNavigationBar: widget.bottomNavigationBar,
    );
  }
}
