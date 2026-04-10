import 'package:flutter/foundation.dart';

enum NavigationKeys {
  contactsDestination,
  roomsDestination,
  settingsDestination,
  breakpointMobile,
  breakpointWebAndDesktop,
  bottomNavigation,
  primaryNavigation,
  adaptiveAppBar;

  Key get key => Key('navigation.$name');

  ValueKey<String> get valueKey => ValueKey('navigation.$name');
}
