sealed class ThreadException implements Exception {
  const ThreadException();
}

class ThreadRoomNotFoundException extends ThreadException {
  const ThreadRoomNotFoundException(this.roomId);

  final String roomId;

  @override
  String toString() => 'ThreadRoomNotFoundException($roomId)';
}

class ThreadLoadFailedException extends ThreadException {
  const ThreadLoadFailedException(this.roomId);

  final String roomId;

  @override
  String toString() => 'ThreadLoadFailedException($roomId)';
}
