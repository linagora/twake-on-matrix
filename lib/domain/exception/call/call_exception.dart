sealed class CallException implements Exception {
  const CallException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'CallException: $message ($cause)';
}

class CallNoClientException extends CallException {
  const CallNoClientException() : super('No signed-in account');
}

class CallRoomNotFoundException extends CallException {
  const CallRoomNotFoundException() : super('The room is not joined');
}

class CallNoPermissionException extends CallException {
  const CallNoPermissionException()
    : super('Not allowed to send a call membership in this room');
}

class CallTokenFailedException extends CallException {
  const CallTokenFailedException({super.cause})
    : super('The token service gave no LiveKit token');
}

class CallMembershipFailedException extends CallException {
  const CallMembershipFailedException({super.cause})
    : super('Failed to send the call membership');
}
