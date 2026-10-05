import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/datasource/video_call/video_call_message_datasource.dart';
import 'package:twake_chat/utils/voip/video_call_helper.dart';

class VideoCallMessageDatasourceImpl implements VideoCallMessageDatasource {
  const VideoCallMessageDatasourceImpl(this._client);

  final Client _client;

  @override
  Future<void> sendCallMessage({
    required String roomId,
    required String url,
    required String body,
  }) async {
    final room = _client.getRoomById(roomId);
    if (room == null) {
      Logs().w(
        'VideoCallMessageDatasourceImpl::sendCallMessage: room not found',
      );
      return;
    }
    await room.sendEvent({
      'msgtype': MessageTypes.Text,
      'body': body,
      VideoCallHelper.callUrlKey: url,
    });
  }
}
