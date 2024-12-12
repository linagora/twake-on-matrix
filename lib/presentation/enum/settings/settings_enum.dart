import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

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
  deleteAccount,
  logout;

  String titleSettings(BuildContext context) {
    switch (this) {
      case SettingEnum.chatSettings:
        return L10n.of(context)!.chat;
      case SettingEnum.privacyAndSecurity:
        return L10n.of(context)!.privacyAndSecurity;
      case SettingEnum.notificationAndSounds:
        return L10n.of(context)!.notifications;
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
      case SettingEnum.deleteAccount:
        return L10n.of(context)!.deleteAccount;
      case SettingEnum.logout:
        return L10n.of(context)!.logout;
      default:
        return '';
    }
  }

  IconData iconLeading() {
    switch (this) {
      case SettingEnum.chatSettings:
        return Icons.chat_bubble_outline_outlined;
      case SettingEnum.privacyAndSecurity:
        return Icons.lock_outline;
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
      case SettingEnum.deleteAccount:
        return Icons.delete_outline;
      case SettingEnum.logout:
        return Icons.logout_outlined;
      default:
        return Icons.person_outline;
    }
  }

  Color? iconColor(BuildContext context) {
    switch (this) {
      case SettingEnum.deleteAccount:
      case SettingEnum.logout:
        return Theme.of(context).colorScheme.error;
      default:
        return LinagoraRefColors.material().tertiary[30];
    }
  }

  Color? titleColor(BuildContext context) {
    switch (this) {
      case SettingEnum.deleteAccount:
        return Theme.of(context).colorScheme.error;
      default:
        return LinagoraSysColors.material().onSurface;
    }
  }

  bool get isHideTrailingIcon =>
      this == SettingEnum.logout || this == SettingEnum.deleteAccount;
}
