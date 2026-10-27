import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/datasource/video_call/video_call_message_datasource.dart';
import 'package:twake_chat/utils/voip/video_call_helper.dart';

class VideoCallMessageDatasourceImpl implements VideoCallMessageDatasource {
  const VideoCallMessageDatasourceImpl(this._client);

  final Client _client;

  @override
  bool isJoined(String roomId) {
    final hasJoined =
        _client.getRoomById(roomId)?.membership == Membership.join;
    if (!hasJoined) {
      Logs().w('VideoCallMessageDatasourceImpl::isJoined: room left');
    }
    return hasJoined;
  }

  @override
  Future<void> sendCallMessage({
    required String roomId,
    required String url,
    required String body,
  }) async {
    // Only called right after isJoined, in the same synchronous run.
    await _client.getRoomById(roomId)!.sendEvent({
      'msgtype': MessageTypes.Text,
      'body': body,
      VideoCallHelper.callUrlKey: url,
    });
  }
}
