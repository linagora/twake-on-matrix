import 'package:matrix/matrix.dart';

import 'package:twake_chat/config/feed_config.dart';

extension ClientFeedExtension on Client {
  /// Raw request rather than [createGroupChat] because
  /// [CreateRoomPreset] is a closed Dart enum: the feed preset cannot be
  /// custom.
  ///
  /// Throws a [MatrixException] on a homeserver that does not know the preset.
  Future<String> createFeedRoom({
    String? feedName,
    List<StateEvent>? initialState,
    Map<String, dynamic>? powerLevelContentOverride,
  }) async {
    final response = await request(
      RequestType.POST,
      '/client/v3/createRoom',
      data: {
        'preset': FeedConfig.preset,
        'creation_content': {'type': FeedConfig.roomType},
        if (feedName != null) 'name': feedName,
        if (initialState != null)
          'initial_state': initialState.map((state) => state.toJson()).toList(),
        if (powerLevelContentOverride != null)
          'power_level_content_override': powerLevelContentOverride,
      },
    );

    final roomId = response['room_id'] as String;

    // Navigating to the room fails if it has not reached the sync yet.
    if (getRoomById(roomId) == null) {
      await waitForRoomInSync(roomId, join: true);
    }

    return roomId;
  }
}
