import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';

enum SettingsContactsVisibilityEnum {
  private,
  public,
  contacts;

  String title(BuildContext context) {
    switch (this) {
      case SettingsContactsVisibilityEnum.public:
        return L10n.of(context)!.everyOne;
      case SettingsContactsVisibilityEnum.contacts:
        return L10n.of(context)!.myContacts;
      case SettingsContactsVisibilityEnum.private:
        return L10n.of(context)!.nobody;
    }
  }

  bool enableDivider() {
    switch (this) {
      case SettingsContactsVisibilityEnum.public:
        return true;
      case SettingsContactsVisibilityEnum.contacts:
        return true;
      case SettingsContactsVisibilityEnum.private:
        return false;
    }
  }
}
