import 'dart:async';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/data/hive/hive_collection_tom_database.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/event/twake_inapp_event_types.dart';
import 'package:fluffychat/pages/bootstrap/bootstrap_dialog.dart';
import 'package:fluffychat/pages/connect/connect_page_mixin.dart';
import 'package:fluffychat/presentation/enum/settings/settings_enum.dart';
import 'package:fluffychat/presentation/extensions/client_extension.dart';
import 'package:fluffychat/utils/url_launcher.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
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
  final ValueNotifier<Profile> profileNotifier = ValueNotifier(
    Profile(userId: ''),
  );

  StreamSubscription? onAccountDataSubscription;

  final List<SettingEnum> getListSettingItem = [
    SettingEnum.chatSettings,
    SettingEnum.privacyAndSecurity,
    SettingEnum.notificationAndSounds,
    SettingEnum.chatFolders,
    SettingEnum.appLanguage,
    SettingEnum.devices,
    SettingEnum.help,
    SettingEnum.logout,
  ];

  final ValueNotifier<SettingEnum?> optionsSelectNotifier = ValueNotifier(null);

  String get displayName =>
      profileNotifier.value.displayName ??
      client.mxid(context).localpart ??
      client.mxid(context);

  bool optionSelected(SettingEnum settingEnum) =>
      settingEnum == optionsSelectNotifier.value;

  void logoutAction() async {
    final noBackup = showChatBackupBanner == true;
    if (await showOkCancelAlertDialog(
          useRootNavigator: false,
          context: context,
          title: L10n.of(context)!.areYouSureYouWantToLogout,
          message: L10n.of(context)!.noBackupWarning,
          isDestructiveAction: noBackup,
          okLabel: L10n.of(context)!.logout,
          cancelLabel: L10n.of(context)!.cancel,
        ) ==
        OkCancelResult.cancel) {
      return;
    }
    await tryLogoutSso(context);
    final hiveCollectionToMDatabase = getIt.get<HiveCollectionToMDatabase>();
    await hiveCollectionToMDatabase.clear();
    final matrix = Matrix.of(context);
    await showFutureLoadingDialog(
      context: context,
      future: () => matrix.client.logout(),
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
    profileNotifier.value = profile;
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
    final needsBootstrap =
        await client.encryption?.keyManager.isCached() == false ||
            client.encryption?.crossSigning.enabled == false ||
            crossSigning == false;
    final isUnknownSession = client.isUnknownSession;
    setState(() {
      showChatBackupBanner = needsBootstrap || isUnknownSession;
    });
  }

  bool? crossSigningCached;
  bool? showChatBackupBanner;

  void firstRunBootstrapAction([_]) async {
    if (showChatBackupBanner != true) {
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
    ).show(context);
    checkBootstrap();
  }

  void goToSettingsProfile(Profile? profile) async {
    optionsSelectNotifier.value = SettingEnum.profile;
    context.push(
      '/rooms/profile',
      extra: profile,
    );
  }

  void onClickToSettingsItem(SettingEnum settingEnum) {
    optionsSelectNotifier.value = settingEnum;
    switch (settingEnum) {
      case SettingEnum.chatSettings:
        context.go('/rooms/chat');
        break;
      case SettingEnum.privacyAndSecurity:
        context.go('/rooms/security');
        break;
      case SettingEnum.notificationAndSounds:
        context.go('/rooms/notifications');
        break;
      case SettingEnum.chatFolders:
        break;
      case SettingEnum.appLanguage:
        break;
      case SettingEnum.devices:
        context.go('/rooms/devices');
        break;
      case SettingEnum.help:
        UrlLauncher(
          context,
          AppConfig.supportUrl,
        ).openUrlInAppBrowser();
        break;
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
        profileNotifier.value = Profile.fromJson(event.content);
      }
    });
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
  void dispose() {
    onAccountDataSubscription?.cancel();
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
