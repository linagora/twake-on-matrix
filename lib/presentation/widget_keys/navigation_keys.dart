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
  activityDestination(
    Key('navigation.activityDestination'),
    ValueKey('navigation.activityDestination'),
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
  ),
  searchButton(
    Key('navigation.searchButton'),
    ValueKey('navigation.searchButton'),
  ),
  searchField(
    Key('navigation.searchField'),
    ValueKey('navigation.searchField'),
  ),
  searchCloseButton(
    Key('navigation.searchCloseButton'),
    ValueKey('navigation.searchCloseButton'),
  ),
  collapsingSearchField(
    Key('navigation.collapsingSearchField'),
    ValueKey('navigation.collapsingSearchField'),
  ),
  settingsAvatar(
    Key('navigation.settingsAvatar'),
    ValueKey('navigation.settingsAvatar'),
  );

  const NavigationKeys(this.key, this.valueKey);

  final Key key;
  final ValueKey<String> valueKey;
}
