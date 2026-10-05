import 'package:matrix/matrix.dart' show Client;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/pages/chat/providers/video_call_providers.dart';

part 'chat_video_call_view_model.g.dart';

@riverpod
class ChatVideoCallViewModel extends _$ChatVideoCallViewModel {
  @override
  AsyncValue<void> build({required Client client, required String roomId}) =>
      const AsyncData(null);

  /// Does nothing while a call is already starting.
  Future<void> start({
    required String baseUrl,
    required String startedTitle,
  }) async {
    if (state.isLoading) return;
    final link = ref.keepAlive();
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(startVideoCallInteractorProvider(client))
          .execute(
            roomId: roomId,
            baseUrl: baseUrl,
            startedTitle: startedTitle,
          ),
    );
    link.close();
    if (!ref.mounted) return;
    state = result;
  }
}
