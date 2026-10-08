sealed class VideoCallException implements Exception {
  const VideoCallException(this.message, {this.cause});

  final String message;
  final Object? cause;
}

/// The server cannot create rooms: the link has to be generated locally.
class VideoCallRoomCreationUnavailableException extends VideoCallException {
  const VideoCallRoomCreationUnavailableException()
    : super('Video call room creation is not available');
}

class VideoCallRoomCreationFailedException extends VideoCallException {
  const VideoCallRoomCreationFailedException({required Object super.cause})
    : super('Failed to create the video call room');
}
