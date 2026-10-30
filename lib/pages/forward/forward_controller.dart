import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/forward/usecases/forward_messages_usecase.provider.dart';
import 'package:twake_chat/pages/forward/forward_state.dart';

part 'forward_controller.g.dart';

@riverpod
class ForwardController extends _$ForwardController {
  @override
  ForwardState build() => const ForwardState.idle();

  Future<void> forward({
    required List<Map<String, Object?>> messages,
    required List<String> roomIds,
  }) async {
    if (state is ForwardSending) return;
    if (_hasNothingToSend(messages, roomIds)) return;
    state = const ForwardState.sending();
    try {
      final result = await ref
          .read(forwardMessagesUseCaseProvider)
          .execute(messages: messages, roomIds: roomIds);
      if (!ref.mounted) return;
      state = ForwardState.done(
        successCount: result.successCount,
        totalCount: result.totalCount,
      );
    } catch (_) {
      // The finally block puts the screen back so the user can retry or leave.
    } finally {
      if (ref.mounted && state is ForwardSending) {
        state = const ForwardState.idle();
      }
    }
  }

  bool _hasNothingToSend(
    List<Map<String, Object?>> messages,
    List<String> roomIds,
  ) => messages.isEmpty || roomIds.isEmpty;
}
