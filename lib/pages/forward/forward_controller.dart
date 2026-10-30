import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/forward/exceptions/forward_exception.dart';
import 'package:twake_chat/domain/forward/usecases/forward_messages_usecase.provider.dart';
import 'package:twake_chat/pages/forward/forward_state.dart';

part 'forward_controller.g.dart';

@riverpod
class ForwardController extends _$ForwardController {
  @override
  ForwardState build() => const ForwardState.selecting();

  void toggleRoom(String roomId) {
    if (state is ForwardSending) return;
    final selected = state.selectedRoomIds;
    state = ForwardState.selecting(
      selectedRoomIds: selected.contains(roomId)
          ? selected.where((id) => id != roomId).toList()
          : [...selected, roomId],
    );
  }

  Future<void> forward(List<Map<String, Object?>> messages) async {
    if (state is ForwardSending) return;
    final roomIds = state.selectedRoomIds;
    state = ForwardState.sending(selectedRoomIds: roomIds);
    try {
      final result = await ref
          .read(forwardMessagesUseCaseProvider)
          .execute(messages: messages, roomIds: roomIds);
      if (!ref.mounted) return;
      state = ForwardState.done(
        selectedRoomIds: roomIds,
        successCount: result.successCount,
        totalCount: result.totalCount,
      );
    } on ForwardException {
      if (!ref.mounted) return;
      state = ForwardState.selecting(selectedRoomIds: roomIds);
    }
  }
}
