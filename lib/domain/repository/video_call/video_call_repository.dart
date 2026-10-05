abstract class VideoCallRepository {
  /// Returns the slug of the created room.
  ///
  /// Throws a `VideoCallRoomCreationUnavailableException` when the server
  /// creates no room, a `VideoCallRoomCreationFailedException` otherwise.
  Future<String> createRoom();

  Future<void> sendCallMessage({
    required String roomId,
    required String url,
    required String body,
  });
}
