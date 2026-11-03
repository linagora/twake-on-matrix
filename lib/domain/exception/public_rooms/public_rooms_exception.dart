sealed class PublicRoomsException implements Exception {
  const PublicRoomsException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'PublicRoomsException: $message ($cause)';
}

class PublicRoomsNoClientException extends PublicRoomsException {
  const PublicRoomsNoClientException() : super('No signed-in account');
}

class PublicRoomsFetchFailedException extends PublicRoomsException {
  const PublicRoomsFetchFailedException({required Object super.cause})
    : super('Failed to fetch the public room directory');
}

class PublicRoomJoinFailedException extends PublicRoomsException {
  const PublicRoomJoinFailedException({required Object super.cause})
    : super('Failed to join the public room');
}

class PublicRoomKnockFailedException extends PublicRoomsException {
  const PublicRoomKnockFailedException({required Object super.cause})
    : super('Failed to ask to join the public room');
}
