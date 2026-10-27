import 'package:twake_chat/data/datasource/video_call/video_call_message_datasource.dart';
import 'package:twake_chat/data/datasource/video_call/video_call_room_datasource.dart';
import 'package:twake_chat/domain/exception/video_call/video_call_exception.dart';
import 'package:twake_chat/domain/repository/video_call/video_call_repository.dart';

class VideoCallRepositoryImpl implements VideoCallRepository {
  const VideoCallRepositoryImpl({
    required VideoCallRoomDatasource roomDatasource,
    required VideoCallMessageDatasource messageDatasource,
  }) : _roomDatasource = roomDatasource,
       _messageDatasource = messageDatasource;

  final VideoCallRoomDatasource _roomDatasource;
  final VideoCallMessageDatasource _messageDatasource;

  @override
  Future<String> createRoom() async {
    final url = (await _roomDatasource.createRoom()).url;
    if (url == null) {
      throw const VideoCallRoomCreationFailedException(
        cause: FormatException('No room url in the response'),
      );
    }
    return url;
  }

  @override
  bool isJoined(String roomId) => _messageDatasource.isJoined(roomId);

  @override
  Future<void> sendCallMessage({
    required String roomId,
    required String url,
    required String body,
  }) =>
      _messageDatasource.sendCallMessage(roomId: roomId, url: url, body: body);
}
