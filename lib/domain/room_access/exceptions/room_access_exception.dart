sealed class RoomAccessException implements Exception {
  const RoomAccessException(this.message, {this.cause});

  final String message;
  final Object? cause;
}

class RoomAccessRoomNotFoundException extends RoomAccessException {
  const RoomAccessRoomNotFoundException() : super('Room not found');
}

/// An encrypted room is never public nor listed in the directory.
class RoomAccessEncryptedException extends RoomAccessException {
  const RoomAccessEncryptedException()
    : super('An encrypted room cannot be public or listed');
}

class RoomAccessPublicPageException extends RoomAccessException {
  const RoomAccessPublicPageException()
    : super('A room with a public page stays public and listed');
}

class RoomAccessForbiddenException extends RoomAccessException {
  const RoomAccessForbiddenException({required Object super.cause})
    : super('The server refused the change');
}

class RoomAccessSaveFailedException extends RoomAccessException {
  const RoomAccessSaveFailedException({required Object super.cause})
    : super('Failed to save the room access');
}
