import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';

enum SettingsContactsVisibilityEnum {
  everyone,
  myContacts,
  nobody;

  String title(BuildContext context) {
    switch (this) {
      case SettingsContactsVisibilityEnum.everyone:
        return L10n.of(context)!.everyOne;
      case SettingsContactsVisibilityEnum.myContacts:
        return L10n.of(context)!.myContacts;
      case SettingsContactsVisibilityEnum.nobody:
        return L10n.of(context)!.nobody;
    }
  }

  bool enableDivider() {
    switch (this) {
      case SettingsContactsVisibilityEnum.everyone:
        return true;
      case SettingsContactsVisibilityEnum.myContacts:
        return true;
      case SettingsContactsVisibilityEnum.nobody:
        return false;
    }
  }
}
