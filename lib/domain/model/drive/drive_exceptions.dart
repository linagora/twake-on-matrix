sealed class DriveException implements Exception {
  const DriveException();
}

class DriveBridgeUnavailableException extends DriveException {
  const DriveBridgeUnavailableException();

  @override
  String toString() => 'DriveBridgeUnavailableException';
}

class DriveAccessTokenMissingException extends DriveException {
  const DriveAccessTokenMissingException();

  @override
  String toString() => 'DriveAccessTokenMissingException';
}

class DriveRoomUnavailableException extends DriveException {
  const DriveRoomUnavailableException();

  @override
  String toString() => 'DriveRoomUnavailableException';
}

/// The stack refused the credentials (invalid or expired token).
class DriveAuthRejectedException extends DriveException {
  const DriveAuthRejectedException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'DriveAuthRejectedException($statusCode)';
}

/// Any other failure of a request to the stack: bad request, server error,
/// conflict, timeout. [statusCode] is null when there was no answer.
class DriveRequestFailedException extends DriveException {
  const DriveRequestFailedException([this.statusCode]);

  final int? statusCode;

  @override
  String toString() => 'DriveRequestFailedException($statusCode)';
}
