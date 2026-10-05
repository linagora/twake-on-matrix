import 'package:matrix/matrix.dart' show Client;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/video_call/video_call_repository.provider.dart';
import 'package:twake_chat/domain/usecase/video_call/start_video_call_interactor.dart';

part 'video_call_providers.g.dart';

@riverpod
StartVideoCallInteractor startVideoCallInteractor(Ref ref, Client client) =>
    StartVideoCallInteractor(
      ref.watch(videoCallRepositoryProvider(client)),
      ref.watch(videoCallSlugServiceProvider),
    );
