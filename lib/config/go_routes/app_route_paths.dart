/// Route path constants for the application.
///
/// This file contains all route paths used in go_router configuration
/// and navigation calls to ensure consistency and prevent typos.
abstract class AppRoutePaths {
  // Settings prefix check
  static const String roomsSettings = '/rooms/settings';

  // Profile routes
  static const String profileSegment = 'profile';
  static const String profileFull = '/rooms/$profileSegment';
  static const String profileQrSegment = 'qr';
  static const String profileQrFull = '$profileFull/$profileQrSegment';

  // Chat settings routes
  static const String chatSegment = 'chat';
  static const String chatFull = '/rooms/$chatSegment';
  static const String emotesSegment = 'emotes';
  static const String chatEmotesFull = '$chatFull/$emotesSegment';

  // Security routes
  static const String securitySegment = 'security';
  static const String roomsSecurityFull = '/rooms/$securitySegment';
  static const String contactsVisibilitySegment = 'contactsVisibility';
  static const String contactsVisibilityFull =
      '$roomsSecurityFull/$contactsVisibilitySegment';
  static const String storiesSegment = 'stories';
  static const String securityStoriesFull =
      '$roomsSecurityFull/$storiesSegment';
  static const String blockedUsersSegment = 'blockedUsers';
  static const String securityBlockedUsersFull =
      '$roomsSecurityFull/$blockedUsersSegment';
  static const String threePidSegment = '3pid';
  static const String securityThreePidFull =
      '$roomsSecurityFull/$threePidSegment';

  // Notifications routes
  static const String notificationsSegment = 'notifications';
  static const String notificationsFull = '/rooms/$notificationsSegment';

  // Style routes
  static const String styleSegment = 'style';
  static const String styleFull = '/rooms/$styleSegment';

  // App language routes
  static const String appLanguageSegment = 'appLanguage';
  static const String appLanguageFull = '/rooms/$appLanguageSegment';

  // Devices routes
  static const String devicesSegment = 'devices';
  static const String devicesFull = '/rooms/$devicesSegment';

  // Add account routes
  static const String addAccountSegment = 'addaccount';
  static const String addAccountFull = '/rooms/$addAccountSegment';
  static const String addAccountLoginSegment = 'login';
  static const String addAccountLoginFull =
      '$addAccountFull/$addAccountLoginSegment';
  static const String addAccountHomeserverPickerSegment = 'homeserverpicker';
  static const String addAccountHomeserverPickerFull =
      '$addAccountFull/$addAccountHomeserverPickerSegment';
}
