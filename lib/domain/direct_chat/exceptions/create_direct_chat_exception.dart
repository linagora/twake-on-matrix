sealed class CreateDirectChatException implements Exception {
  const CreateDirectChatException();
}

/// The server forbids reading the contact's profile, so no chat can be created.
class CreateDirectChatForbiddenException extends CreateDirectChatException {
  const CreateDirectChatForbiddenException();
}

/// Any other failure while creating or joining the chat.
class CreateDirectChatFailedException extends CreateDirectChatException {
  const CreateDirectChatFailedException(this.cause);

  final Object cause;

  @override
  String toString() => 'CreateDirectChatFailedException: $cause';
}

/// The room found or created is not a usable direct chat with the contact.
class CreateDirectChatRoomMismatchException extends CreateDirectChatException {
  const CreateDirectChatRoomMismatchException({
    required this.roomId,
    required this.contactMxId,
  });

  final String roomId;
  final String contactMxId;
}
