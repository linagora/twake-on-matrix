import 'dart:async';

import 'package:dio/dio.dart';
import 'package:matrix/matrix.dart' show Logs;
import 'package:twake_chat/data/datasource/video_call/video_call_room_datasource.dart';
import 'package:twake_chat/data/model/video_call/create_video_call_room_response.dart';
import 'package:twake_chat/data/network/interceptor/dynamic_url_interceptor.dart';
import 'package:twake_chat/data/network/video_call/video_call_api.dart';
import 'package:twake_chat/domain/exception/video_call/video_call_exception.dart';

class VideoCallRoomDatasourceImpl implements VideoCallRoomDatasource {
  const VideoCallRoomDatasourceImpl({
    required VideoCallApi videoCallApi,
    required DynamicUrlInterceptors tomServerUrlInterceptor,
  }) : _videoCallApi = videoCallApi,
       _tomServerUrlInterceptor = tomServerUrlInterceptor;

  static const _createRoomTimeout = Duration(seconds: 20);

  /// 404: the server creates no room; 422: none for this user (no usable email).
  static const _unavailableStatusCodes = {404, 422};

  final VideoCallApi _videoCallApi;
  final DynamicUrlInterceptors _tomServerUrlInterceptor;

  @override
  Future<CreateVideoCallRoomResponse> createRoom() async {
    if (_tomServerUrlInterceptor.baseUrl == null) {
      throw const VideoCallRoomCreationUnavailableException();
    }
    final cancelToken = CancelToken();
    try {
      return await _videoCallApi
          .createRoom(cancelToken: cancelToken)
          .timeout(_createRoomTimeout);
    } on TimeoutException catch (exception, stackTrace) {
      cancelToken.cancel();
      throw _toVideoCallException(exception, stackTrace);
    } on Exception catch (exception, stackTrace) {
      throw _toVideoCallException(exception, stackTrace);
    }
  }

  VideoCallException _toVideoCallException(
    Exception exception,
    StackTrace stackTrace,
  ) {
    if (exception is DioException &&
        _unavailableStatusCodes.contains(exception.response?.statusCode)) {
      Logs().w('VideoCallRoomDatasourceImpl::createRoom: not available');
      return const VideoCallRoomCreationUnavailableException();
    }
    Logs().e('VideoCallRoomDatasourceImpl::createRoom', exception, stackTrace);
    return VideoCallRoomCreationFailedException(cause: exception);
  }
}
