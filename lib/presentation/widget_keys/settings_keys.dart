import 'package:flutter/foundation.dart';

enum SettingsKeys {
  contactsVisibilityItem(
    Key('settings.contactsVisibilityItem'),
    ValueKey('settings.contactsVisibilityItem'),
  ),
  recoveryKeyItem(
    Key('settings.recoveryKeyItem'),
    ValueKey('settings.recoveryKeyItem'),
  ),
  recoveryKeyCopyButton(
    Key('settings.recoveryKeyCopyButton'),
    ValueKey('settings.recoveryKeyCopyButton'),
  ),
  profileViewMobile(
    Key('settings.profileViewMobile'),
    ValueKey('settings.profileViewMobile'),
  ),
  profileViewWeb(
    Key('settings.profileViewWeb'),
    ValueKey('settings.profileViewWeb'),
  ),
  listViewContent(
    Key('settings.listViewContent'),
    ValueKey('settings.listViewContent'),
  );

  const SettingsKeys(this.key, this.valueKey);

  final Key key;
  final ValueKey<String> valueKey;
}
