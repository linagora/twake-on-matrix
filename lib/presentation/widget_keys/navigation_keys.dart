import 'package:flutter/foundation.dart';

enum NavigationKeys {
  contactsDestination(
    Key('navigation.contactsDestination'),
    ValueKey('navigation.contactsDestination'),
  ),
  roomsDestination(
    Key('navigation.roomsDestination'),
    ValueKey('navigation.roomsDestination'),
  ),
  settingsDestination(
    Key('navigation.settingsDestination'),
    ValueKey('navigation.settingsDestination'),
  ),
  breakpointMobile(
    Key('navigation.breakpointMobile'),
    ValueKey('navigation.breakpointMobile'),
  ),
  breakpointWebAndDesktop(
    Key('navigation.breakpointWebAndDesktop'),
    ValueKey('navigation.breakpointWebAndDesktop'),
  ),
  bottomNavigation(
    Key('navigation.bottomNavigation'),
    ValueKey('navigation.bottomNavigation'),
  ),
  primaryNavigation(
    Key('navigation.primaryNavigation'),
    ValueKey('navigation.primaryNavigation'),
  ),
  adaptiveAppBar(
    Key('navigation.adaptiveAppBar'),
    ValueKey('navigation.adaptiveAppBar'),
  );

  const NavigationKeys(this.key, this.valueKey);

  final Key key;
  final ValueKey<String> valueKey;
}
