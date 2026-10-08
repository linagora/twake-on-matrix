import 'package:dio/dio.dart' show CancelToken;
import 'package:twake_chat/data/model/video_call/create_video_call_room_response.dart';
import 'package:twake_chat/data/network/dio_client.dart';
import 'package:twake_chat/data/network/tom_endpoint.dart';

class VideoCallApi {
  const VideoCallApi(this._client);

  final DioClient _client;

  Future<CreateVideoCallRoomResponse> createRoom({
    CancelToken? cancelToken,
  }) async {
    final body = await _client.postToGetBody(
      TomEndpoint.videoCallRoomsServicePath.generateTomEndpoint(),
      data: const <String, dynamic>{},
      cancelToken: cancelToken,
    );
    if (body is! Map<String, dynamic>) {
      throw const FormatException('Unexpected response body');
    }
    return CreateVideoCallRoomResponse.fromJson(body);
  }
}
