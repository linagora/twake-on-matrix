import 'package:matrix/matrix.dart' show Client;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource_impl/video_call/video_call_message_datasource.provider.dart';
import 'package:twake_chat/data/datasource_impl/video_call/video_call_room_datasource.provider.dart';
import 'package:twake_chat/data/repository/video_call/video_call_repository_impl.dart';
import 'package:twake_chat/domain/repository/video_call/video_call_repository.dart';

part 'video_call_repository.provider.g.dart';

// TODO: [transitional] Keyed by Client until matrixClientProvider exists (plan v2, Step 1).
@riverpod
VideoCallRepository videoCallRepository(Ref ref, Client client) =>
    VideoCallRepositoryImpl(
      roomDatasource: ref.watch(videoCallRoomDatasourceProvider),
      messageDatasource: ref.watch(videoCallMessageDatasourceProvider(client)),
    );
