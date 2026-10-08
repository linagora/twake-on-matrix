import 'package:twake_chat/data/datasource/video_call/video_call_message_datasource.dart';
import 'package:twake_chat/data/datasource/video_call/video_call_room_datasource.dart';
import 'package:twake_chat/domain/exception/video_call/video_call_exception.dart';
import 'package:twake_chat/domain/repository/video_call/video_call_repository.dart';
import 'package:twake_chat/domain/services/video_call/video_call_slug_service.dart';

class VideoCallRepositoryImpl implements VideoCallRepository {
  const VideoCallRepositoryImpl({
    required VideoCallRoomDatasource roomDatasource,
    required VideoCallMessageDatasource messageDatasource,
    required VideoCallSlugService slugService,
  }) : _roomDatasource = roomDatasource,
       _messageDatasource = messageDatasource,
       _slugService = slugService;

  final VideoCallRoomDatasource _roomDatasource;
  final VideoCallMessageDatasource _messageDatasource;
  final VideoCallSlugService _slugService;

  @override
  Future<String> createRoom() async {
    final url = (await _roomDatasource.createRoom()).url;
    final slug = url == null ? null : _slugService.parse(url);
    if (slug == null) {
      throw const VideoCallRoomCreationFailedException(
        cause: FormatException('No usable room url in the response'),
      );
    }
    return slug;
  }

  @override
  Future<void> sendCallMessage({
    required String roomId,
    required String url,
    required String body,
  }) =>
      _messageDatasource.sendCallMessage(roomId: roomId, url: url, body: body);
}
