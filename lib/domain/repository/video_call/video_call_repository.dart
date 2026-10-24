abstract class VideoCallRepository {
  /// Returns the url of the created room.
  ///
  /// Throws a `VideoCallRoomCreationUnavailableException` when the server
  /// creates no room, a `VideoCallRoomCreationFailedException` otherwise.
  Future<String> createRoom();

  bool isJoined(String roomId);

  Future<void> sendCallMessage({
    required String roomId,
    required String url,
    required String body,
  });
}
