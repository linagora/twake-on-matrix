import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/room/create_new_group_chat_state.dart';
import 'package:fluffychat/domain/exception/room/can_not_create_new_group_chat_exception.dart';
import 'package:fluffychat/domain/model/room/create_new_group_chat_request.dart';
import 'package:matrix/matrix.dart';

class CreateNewGroupChatInteractor {
  Stream<Either<Failure, Success>> execute({
    required Client matrixClient,
    required CreateNewGroupChatRequest createNewGroupChatRequest,
  }) async* {
    try {
      yield Right(CreateNewGroupChatLoading());

      final addAvatarStateEvent = StateEvent(
        type: EventTypes.RoomAvatar,
        content: {
          'url': createNewGroupChatRequest.urlAvatar,
        },
        stateKey: '',
      );
      final historyVisibility =
          createNewGroupChatRequest.enableEncryption == true
              ? HistoryVisibility.joined
              : HistoryVisibility.shared;
      final historyVisibilityStateEvent = StateEvent(
        type: EventTypes.HistoryVisibility,
        content: {'history_visibility': historyVisibility.name},
        stateKey: '',
      );

      final roomId = await matrixClient.createGroupChat(
        groupName: createNewGroupChatRequest.groupName,
        invite: createNewGroupChatRequest.invite,
        enableEncryption: createNewGroupChatRequest.enableEncryption,
        preset: createNewGroupChatRequest.createRoomPreset,
        initialState: [addAvatarStateEvent, historyVisibilityStateEvent],
        powerLevelContentOverride:
            createNewGroupChatRequest.powerLevelContentOverride,
      );

      if (roomId.isNotEmpty) {
        yield Right(
          CreateNewGroupChatSuccess(
            roomId: roomId,
            groupName: createNewGroupChatRequest.groupName,
          ),
        );
      } else {
        yield Left(
          CreateNewGroupChatFailed(
            exception: CannotCreateNewGroupChatException(),
          ),
        );
      }
    } catch (exception) {
      yield Left(CreateNewGroupChatFailed(exception: exception));
    }
  }
}
