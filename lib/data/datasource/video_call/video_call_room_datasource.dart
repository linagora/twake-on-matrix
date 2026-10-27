import 'package:twake_chat/data/model/video_call/create_video_call_room_response.dart';

abstract class VideoCallRoomDatasource {
  /// Throws a `VideoCallRoomCreationUnavailableException` when the server
  /// creates no room, a `VideoCallRoomCreationFailedException` otherwise.
  Future<CreateVideoCallRoomResponse> createRoom();
}
