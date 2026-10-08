import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource/video_call/video_call_room_datasource.dart';
import 'package:twake_chat/data/datasource_impl/video_call/video_call_room_datasource_impl.dart';
import 'package:twake_chat/data/network/video_call/video_call_api.provider.dart';
import 'package:twake_chat/di/global/tom_network_providers.dart';

part 'video_call_room_datasource.provider.g.dart';

@riverpod
VideoCallRoomDatasource videoCallRoomDatasource(Ref ref) =>
    VideoCallRoomDatasourceImpl(
      videoCallApi: ref.watch(videoCallApiProvider),
      tomServerUrlInterceptor: ref.watch(tomServerUrlInterceptorProvider),
    );
