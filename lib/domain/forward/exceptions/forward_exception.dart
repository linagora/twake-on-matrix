sealed class ForwardException implements Exception {
  const ForwardException();
}

class ForwardRoomNotFoundException extends ForwardException {
  const ForwardRoomNotFoundException(this.roomId);

  final String roomId;

  @override
  String toString() => 'ForwardRoomNotFoundException($roomId)';
}

class ForwardSendFailedException extends ForwardException {
  const ForwardSendFailedException(this.roomId);

  final String roomId;

  @override
  String toString() => 'ForwardSendFailedException($roomId)';
}
