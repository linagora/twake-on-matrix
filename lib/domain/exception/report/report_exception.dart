sealed class ReportException implements Exception {
  const ReportException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'ReportException: $message ($cause)';
}

class ReportNoClientException extends ReportException {
  const ReportNoClientException() : super('No signed-in account');
}

class ReportRoomFailedException extends ReportException {
  const ReportRoomFailedException({
    required this.roomId,
    required Object super.cause,
  }) : super('Failed to report the room');

  final String roomId;
}

class ReportUserFailedException extends ReportException {
  const ReportUserFailedException({
    required this.userId,
    required Object super.cause,
  }) : super('Failed to report the user');

  final String userId;
}
