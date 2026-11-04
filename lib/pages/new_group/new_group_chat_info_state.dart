import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:twake_chat/domain/exception/room/invite_user_exception.dart';

part 'new_group_chat_info_state.freezed.dart';

enum NewGroupFailureReason { feedNotSupported, other }

@freezed
sealed class NewGroupChatInfoState with _$NewGroupChatInfoState {
  const NewGroupChatInfoState._();

  const factory NewGroupChatInfoState.idle() = NewGroupChatInfoIdle;

  const factory NewGroupChatInfoState.creating() = NewGroupChatInfoCreating;

  const factory NewGroupChatInfoState.inviting() = NewGroupChatInfoInviting;

  const factory NewGroupChatInfoState.done({
    required String roomId,
    String? groupName,
    InviteUserPartialFailureException? inviteFailure,
  }) = NewGroupChatInfoDone;

  const factory NewGroupChatInfoState.failed(NewGroupFailureReason reason) =
      NewGroupChatInfoFailed;

  bool get isBusy =>
      this is NewGroupChatInfoCreating || this is NewGroupChatInfoInviting;
}
