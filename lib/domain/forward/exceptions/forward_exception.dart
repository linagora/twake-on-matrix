sealed class ForwardException implements Exception {
  const ForwardException();
}

class ForwardEmptyContentException extends ForwardException {
  const ForwardEmptyContentException();
}

class ForwardRoomNotFoundException extends ForwardException {
  const ForwardRoomNotFoundException(this.roomId);

  final String roomId;

  @override
  String toString() => 'ForwardRoomNotFoundException($roomId)';
}
