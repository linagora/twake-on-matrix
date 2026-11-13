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

/// The well-known has no token service: the call link is the fallback.
class CallServiceUnavailableException extends CallException {
  const CallServiceUnavailableException()
    : super('No MatrixRTC token service in the well-known');
}

class CallConnectionFailedException extends CallException {
  const CallConnectionFailedException({super.cause})
    : super('Failed to connect to LiveKit');
}

class CallMediaFailedException extends CallException {
  const CallMediaFailedException({super.cause})
    : super('Failed to open the microphone or the camera');
}

/// Encryption was turned on in the room during a call in the clear
/// (DECISION.md D14): joining again encrypts it.
class CallEncryptionTurnedOnException extends CallException {
  const CallEncryptionTurnedOnException()
    : super('Encryption was turned on during the call');
}
