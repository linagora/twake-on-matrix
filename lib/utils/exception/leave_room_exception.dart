class LeaveChatException implements Exception {
  final dynamic error;

  LeaveChatException({
    this.error,
  });

  @override
  String toString() => error;
}

class RoomNullException extends LeaveChatException {
  RoomNullException()
      : super(
          error:
              'Leave room button clicked while room is null. This should not be possible from the UI!',
        );
}
