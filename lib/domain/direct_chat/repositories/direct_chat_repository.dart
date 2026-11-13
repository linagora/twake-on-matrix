abstract class DirectChatRepository {
  /// Returns the id of the joined direct chat with [contactMxId], reusing an
  /// existing one or creating it.
  ///
  /// Throws [CreateDirectChatForbiddenException] when the server forbids
  /// reading the contact's profile, and [CreateDirectChatFailedException] for
  /// any other failure.
  Future<String> createDirectChat({required String contactMxId});

  /// Whether the room [roomId] exists and is a direct chat usable with
  /// [contactMxId].
  bool isUsableDirectChat({
    required String roomId,
    required String contactMxId,
  });

  /// Returns the id of the existing direct chat with [contactMxId], or null
  /// when there is none or it is abandoned or no longer usable with them.
  String? findDirectChat({required String contactMxId});
}
