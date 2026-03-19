import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';

enum SettingsContactsVisibilityEnum {
  private,
  public,
  contacts;

  String title(BuildContext context) {
    final l10n = L10n.of(context)!;
    switch (this) {
      case .public:
        return l10n.everyOne;
      case .contacts:
        return l10n.myContacts;
      case .private:
        return l10n.nobody;
    }
  }

  bool enableDivider() {
    switch (this) {
      case .public:
        return true;
      case .contacts:
        return true;
      case .private:
        return false;
    }
  }
}
