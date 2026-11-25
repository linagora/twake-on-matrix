import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/video_call/usecases/start_video_call_usecase.dart';
import 'package:twake_chat/pages/chat/chat_video_call_state.dart';

part 'chat_video_call_controller.g.dart';

@riverpod
class ChatVideoCallController extends _$ChatVideoCallController {
  @override
  ChatVideoCallState build(String roomId) => const ChatVideoCallState.idle();

  /// Does nothing while a call is already starting in [roomId].
  ///
  /// Throws a `VideoCallException`.
  Future<void> start(
    StartVideoCallUseCase useCase, {
    required String baseUrl,
    required String startedTitle,
  }) async {
    if (state is ChatVideoCallStarting) return;
    // The button is disposed in selection mode: the flag must outlive it.
    final link = ref.keepAlive();
    state = const ChatVideoCallState.starting();
    try {
      await useCase.execute(
        roomId: roomId,
        baseUrl: baseUrl,
        startedTitle: startedTitle,
      );
    } finally {
      if (ref.mounted) state = const ChatVideoCallState.idle();
      link.close();
    }
  }
}
