/// Route path constants for the application.
///
/// This file contains all route paths used in go_router configuration
/// and navigation calls to ensure consistency and prevent typos.
abstract class AppRoutePaths {
  // Security routes
  static const String roomsSecurityFull = '/rooms/security';
  static const String contactsVisibilitySegment = 'contactsVisibility';
  static const String contactsVisibilityFull =
      '$roomsSecurityFull/$contactsVisibilitySegment';
}
