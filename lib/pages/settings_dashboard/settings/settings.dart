import 'dart:async';

import 'package:twake_chat/config/app_config.dart';

import 'package:twake_chat/domain/model/extensions/common_settings/common_settings_extensions.dart';
import 'package:twake_chat/domain/model/extensions/homeserver_summary_extensions.dart';
import 'package:twake_chat/event/twake_inapp_event_types.dart';
import 'package:twake_chat/pages/bootstrap/bootstrap_dialog.dart';
import 'package:twake_chat/presentation/mixins/connect_page_mixin.dart';
import 'package:twake_chat/presentation/enum/settings/settings_enum.dart';
import 'package:twake_chat/presentation/extensions/client_extension.dart';
import 'package:twake_chat/utils/dialog/twake_dialog.dart';
import 'package:twake_chat/utils/client_logout.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/utils/url_launcher.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:twake_chat/widgets/twake_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/pages/contacts_tab/providers/matrix_profile_providers.dart';
import 'package:twake_chat/providers/push_removals_controller.dart';
import 'package:twake_chat/providers/report_failure_provider.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';

import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:url_launcher/url_launcher.dart';

import 'settings_view.dart';

class Settings extends ConsumerStatefulWidget {
  final Widget? bottomNavigationBar;

  const Settings({super.key, this.bottomNavigationBar});

  @override
  SettingsController createState() => SettingsController();
}

class SettingsController extends ConsumerState<Settings> with ConnectPageMixin {
  final ValueNotifier<Uri?> avatarUriNotifier = ValueNotifier(Uri());
  final ValueNotifier<String?> displayNameNotifier = ValueNotifier('');

  static String generateEmailSubject(String? matrixId) =>
      'Request for Deletion of Twake Chat Account${matrixId != null ? ' - $matrixId' : ''}';

  StreamSubscription? onAccountDataSubscription;

  final List<SettingEnum> getListSettingItem = [
    SettingEnum.chatSettings,
    SettingEnum.privacyAndSecurity,
    SettingEnum.notificationAndSounds,
    SettingEnum.appLanguage,
    SettingEnum.devices,
    if (PlatformInfos.isMobile) SettingEnum.dataAndStorage,
    SettingEnum.help,
    SettingEnum.about,
    SettingEnum.logout,
    if (PlatformInfos.isMobile) SettingEnum.deleteAccount,
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
    final twakeContext = TwakeApp.routerKey.currentContext;
    if (twakeContext == null) {
      Logs().e('SettingsController()::logoutAction - Twake context is null');
    }
    if (await showConfirmAlertDialog(
          useRootNavigator: false,
          context: twakeContext!,
          title: L10n.of(context)!.areYouSureYouWantToLogout,
          message: L10n.of(context)!.logoutDialogWarning,
          okLabel: L10n.of(context)!.logout,
          cancelLabel: L10n.of(context)!.cancel,
        ) ==
        ConfirmResult.cancel) {
      return;
    }

    await _tryToUploadKeyBackup();

    if (PlatformInfos.isMobile) {
      await _logoutActionsOnMobile();
    } else {
      await _logoutActions();
    }
  }

  Future<void> _tryToUploadKeyBackup() async {
    await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () async {
        await matrix.client.encryption?.keyManager.uploadInboundGroupSessions();
      },
    );

    return;
  }

  Future<void> _removePushers() => ref
      .read(pushRemovalsControllerProvider.notifier)
      .removeBeforeLogout(matrix.client);

  Future<void> _logoutActionsOnMobile() async {
    await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () => _logoutClientAndLocalData('_logoutActionsOnMobile'),
    );
  }

  Future<void> _logoutClientAndLocalData(String action) async {
    try {
      await _removePushers();
      // Clearing the client also removes the recovery key
      // (`TwakeClient.clear`).
      await logoutAndCleanUp(
        matrix.client,
        twakeSupported: matrix.twakeSupported,
      );
    } catch (e, s) {
      ref.read(reportFailureProvider)(
        e,
        s,
        'SettingsController()::$action - logout step failed, local cleanup '
        'continues',
      );
    }
  }

  Future<void> _logoutActions() async {
    await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () async {
        await _logoutClientAndLocalData('_logoutActions');
        try {
          await tryLogoutSso(context);
        } catch (e) {
          Logs().e('SettingsController()::_logoutActions - error: $e');
          return;
        }
      },
    );
  }

  Client get client => Matrix.of(context).client;

  void _getCurrentProfile(Client client) async {
    final profile = await ProviderScope.containerOf(
      context,
      listen: false,
    ).read(matrixUserProfileProvider(client.userID!).future);
    Logs().d('Settings::_getCurrentProfile() - currentProfile: $profile');
    avatarUriNotifier.value = profile?.avatarUrl == null
        ? null
        : Uri.tryParse(profile!.avatarUrl!);
    displayNameNotifier.value = profile?.displayName;
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
    await BootstrapDialog(client: Matrix.of(context).client).show();
    checkBootstrap();
  }

  void goToSettingsProfile() async {
    optionsSelectNotifier.value = SettingEnum.profile;
    final result = await const ProfileRoute().push(context);
    if (result == null) {
      optionsSelectNotifier.value = null;
    }
  }

  void onClickToSettingsItem(SettingEnum settingEnum) async {
    optionsSelectNotifier.value = settingEnum;
    switch (settingEnum) {
      case SettingEnum.chatSettings:
        final result = await const ChatSettingsRoute().push(context);
        if (result == null) {
          optionsSelectNotifier.value = null;
        }
        break;
      case SettingEnum.privacyAndSecurity:
        final result = await const SecurityRoute().push(context);
        if (result == null) {
          optionsSelectNotifier.value = null;
        }
        break;
      case SettingEnum.notificationAndSounds:
        final result = await const NotificationsRoute().push(context);
        if (result == null) {
          optionsSelectNotifier.value = null;
        }
        break;
      case SettingEnum.chatFolders:
        break;
      case SettingEnum.appLanguage:
        final result = await const AppLanguageRoute().push(context);
        if (result == null) {
          optionsSelectNotifier.value = null;
        }
        break;
      case SettingEnum.devices:
        final result = await const DevicesRoute().push(context);
        if (result == null) {
          optionsSelectNotifier.value = null;
        }
        break;
      case SettingEnum.dataAndStorage:
        final result = await const DataAndStorageRoute().push(context);
        if (result == null) {
          optionsSelectNotifier.value = null;
        }
        break;
      case SettingEnum.help:
        UrlLauncher(context, url: AppConfig.supportUrl).openUrlInAppBrowser();
        break;
      case SettingEnum.about:
        PlatformInfos.showAboutDialogFullScreen();
      case SettingEnum.logout:
        logoutAction();
        break;
      case SettingEnum.deleteAccount:
        final matrix = Matrix.of(context);
        final userId = matrix.client.userID;
        final commonSettingsInformation = matrix
            .loginHomeserverSummary
            ?.appTwakeInformation
            ?.commonSettingsInformation;
        final commonSettingsUrl = userId == null
            ? null
            : commonSettingsInformation?.completedApplicationUrl(userId);
        if (commonSettingsUrl != null) {
          launchUrl(Uri.parse(commonSettingsUrl), webOnlyWindowName: '_blank');
          return;
        }
        if (await showConfirmAlertDialog(
              useRootNavigator: false,
              context: context,
              title: L10n.of(context)!.areYouSureYouWantToDeleteAccount,
              message: L10n.of(context)!.deleteAccountMessage,
              okLabel: L10n.of(context)!.continueProcess,
              okLabelButtonColor: Colors.transparent,
              okTextColor: LinagoraSysColors.material().primary,
              cancelLabel: L10n.of(context)!.deleteLater,
              cancelLabelButtonColor: LinagoraSysColors.material().primary,
              cancelTextColor: LinagoraSysColors.material().onPrimary,
            ) ==
            ConfirmResult.cancel) {
          return;
        }

        final emailUri = Uri.parse(
          'mailto:${AppConfig.supportEmail}?subject=${Uri.encodeComponent(generateEmailSubject(userId))}',
        );
        if (await canLaunchUrl(emailUri)) {
          await launchUrl(emailUri);
        }

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
    return SettingsView(this, bottomNavigationBar: widget.bottomNavigationBar);
  }
}
