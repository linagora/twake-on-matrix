import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

enum SettingEnum {
  profile,
  chatSettings,
  privacyAndSecurity,
  notificationAndSounds,
  chatFolders,
  appLanguage,
  devices,
  help,
  about,
  logout;

  String titleSettings(BuildContext context) {
    switch (this) {
      case SettingEnum.chatSettings:
        return L10n.of(context)!.chat;
      case SettingEnum.privacyAndSecurity:
        return L10n.of(context)!.privacyAndSecurity;
      case SettingEnum.notificationAndSounds:
        return L10n.of(context)!.notificationAndSounds;
      case SettingEnum.chatFolders:
        return L10n.of(context)!.chatFolders;
      case SettingEnum.appLanguage:
        return L10n.of(context)!.appLanguage;
      case SettingEnum.devices:
        return L10n.of(context)!.devices;
      case SettingEnum.help:
        return L10n.of(context)!.help;
      case SettingEnum.about:
        return L10n.of(context)!.about;
      case SettingEnum.logout:
        return L10n.of(context)!.logout;
      default:
        return '';
    }
  }

  String subtitleSettings(BuildContext context) {
    switch (this) {
      case SettingEnum.chatSettings:
        return '';
      case SettingEnum.privacyAndSecurity:
        return L10n.of(context)!.settingsPrivacyAndSecuritySubtitle;
      case SettingEnum.notificationAndSounds:
        return L10n.of(context)!.settingsNotificationAndSoundsSubtitle;
      case SettingEnum.chatFolders:
        return L10n.of(context)!.settingsChatFoldersSubtitle;
      case SettingEnum.appLanguage:
        return L10n.of(context)!.settingsAppLanguageSubtitle;
      case SettingEnum.devices:
        return L10n.of(context)!.settingsDevicesSubtitle;
      case SettingEnum.help:
        return L10n.of(context)!.settingsHelpSubtitle;
      default:
        return '';
    }
  }

  IconData iconLeading() {
    switch (this) {
      case SettingEnum.chatSettings:
        return Icons.chat_bubble_outline_outlined;
      case SettingEnum.privacyAndSecurity:
        return Icons.lock;
      case SettingEnum.notificationAndSounds:
        return Icons.notifications_none;
      case SettingEnum.chatFolders:
        return Icons.folder_outlined;
      case SettingEnum.appLanguage:
        return Icons.language;
      case SettingEnum.devices:
        return Icons.devices;
      case SettingEnum.help:
        return Icons.question_mark;
      case SettingEnum.about:
        return Icons.privacy_tip_outlined;
      case SettingEnum.logout:
        return Icons.logout_outlined;
      default:
        return Icons.person_outline;
    }
  }

  bool get isHideTrailingIcon => this == SettingEnum.logout;
}
