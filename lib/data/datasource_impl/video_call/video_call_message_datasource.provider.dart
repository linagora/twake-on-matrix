import 'package:matrix/matrix.dart' show Client;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource/video_call/video_call_message_datasource.dart';
import 'package:twake_chat/data/datasource_impl/video_call/video_call_message_datasource_impl.dart';

part 'video_call_message_datasource.provider.g.dart';

// TODO: [transitional] Keyed by Client while chat_video_call_button passes room.client.
@riverpod
VideoCallMessageDatasource videoCallMessageDatasource(Ref ref, Client client) =>
    VideoCallMessageDatasourceImpl(client);
