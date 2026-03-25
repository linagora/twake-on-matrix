import 'package:flutter/foundation.dart';

enum SettingsKeys {
  contactsVisibilityItem,
  recoveryKeyItem,
  recoveryKeyCopyButton,
  profileViewMobile,
  profileViewWeb,
  listViewContent;

  Key get key => Key('settings.$name');

  ValueKey<String> get valueKey => ValueKey('settings.$name');
}
