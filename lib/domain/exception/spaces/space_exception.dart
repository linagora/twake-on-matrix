sealed class SpaceException implements Exception {
  const SpaceException();
}

/// The server, or the power levels of the space, refuse it.
class SpaceForbiddenException extends SpaceException {
  const SpaceForbiddenException();
}

class SpaceCreationFailedException extends SpaceException {
  const SpaceCreationFailedException();
}

class SpaceJoinFailedException extends SpaceException {
  const SpaceJoinFailedException();
}

/// The hierarchy of a space could not be read.
class SpaceChildrenUnavailableException extends SpaceException {
  const SpaceChildrenUnavailableException();
}
