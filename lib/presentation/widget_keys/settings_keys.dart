import 'package:flutter/foundation.dart';

enum SettingsKeys {
  contactsVisibilityItem,
  recoveryKeyItem,
  recoveryKeyCopyButton,
  profileViewMobile,
  profileViewWeb,
  listViewContent;

  Key get key => Key(name);

  ValueKey<String> get valueKey => ValueKey(name);
}
