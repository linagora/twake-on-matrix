import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/direct_chat/usecases/find_direct_chat_usecase.provider.dart';
import 'package:twake_chat/pages/new_private_chat/new_private_chat_state.dart';

part 'new_private_chat_controller.g.dart';

@riverpod
class NewPrivateChatController extends _$NewPrivateChatController {
  @override
  NewPrivateChatState build() => const NewPrivateChatState.idle();

  /// Ends in `room` or `draft`, which the screen navigates to; ignored while
  /// a lookup is running.
  Future<void> openContact({
    required String matrixId,
    String? displayName,
  }) async {
    if (state is NewPrivateChatOpening) return;
    state = const NewPrivateChatState.opening();
    try {
      final roomId = await ref
          .read(findDirectChatUseCaseProvider)
          .execute(contactMxId: matrixId);
      if (!ref.mounted) return;
      state = roomId == null
          ? NewPrivateChatState.draft(
              matrixId: matrixId,
              displayName: displayName,
            )
          : NewPrivateChatState.room(roomId);
    } finally {
      if (ref.mounted && state is NewPrivateChatOpening) {
        state = const NewPrivateChatState.idle();
      }
    }
  }
}
