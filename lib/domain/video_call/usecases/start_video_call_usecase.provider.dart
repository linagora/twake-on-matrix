import 'package:matrix/matrix.dart' show Client;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/video_call/video_call_repository.provider.dart';
import 'package:twake_chat/domain/services/video_call/video_call_slug_service.provider.dart';
import 'package:twake_chat/domain/video_call/usecases/start_video_call_usecase.dart';

part 'start_video_call_usecase.provider.g.dart';

// TODO: [transitional] Keyed by Client until matrixClientProvider exists (plan v2, Step 1).
@riverpod
StartVideoCallUseCase startVideoCallUseCase(Ref ref, Client client) =>
    StartVideoCallUseCase(
      ref.watch(videoCallRepositoryProvider(client)),
      ref.watch(videoCallSlugServiceProvider),
    );
