import 'package:flutter/foundation.dart';

enum NavigationKeys {
  contactsDestination,
  roomsDestination,
  settingsDestination,
  scaffoldWithNestedNavigation,
  breakpointMobile,
  breakpointWebAndDesktop,
  bottomNavigation,
  primaryNavigation,
  adaptiveAppBar;

  Key get key => Key(name);

  ValueKey<String> get valueKey => ValueKey(name);
}
