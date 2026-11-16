import 'package:freezed_annotation/freezed_annotation.dart';

part 'new_private_chat_state.freezed.dart';

@freezed
sealed class NewPrivateChatState with _$NewPrivateChatState {
  const factory NewPrivateChatState.idle() = NewPrivateChatIdle;

  const factory NewPrivateChatState.opening() = NewPrivateChatOpening;

  const factory NewPrivateChatState.room(String roomId) = NewPrivateChatRoom;

  const factory NewPrivateChatState.draft({
    required String matrixId,
    String? displayName,
  }) = NewPrivateChatDraft;
}
