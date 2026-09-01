class CannotCreateNewGroupChatException implements Exception {
  CannotCreateNewGroupChatException() : super();
}

class CannotCreateNewGroupChatWithLimitedPermissionsException
    implements Exception {
  CannotCreateNewGroupChatWithLimitedPermissionsException() : super();
}

class FederationDeniedWithMatrixOrgException implements Exception {
  FederationDeniedWithMatrixOrgException() : super();
}

/// The homeserver does not know the feed preset, most likely because it has not
/// been patched yet.
class FeedNotSupportedByHomeserverException implements Exception {
  FeedNotSupportedByHomeserverException() : super();
}
