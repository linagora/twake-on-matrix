import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/room/update_group_chat_failure.dart';
import 'package:fluffychat/domain/app_state/room/update_group_chat_loading.dart';
import 'package:fluffychat/domain/app_state/room/update_group_chat_success.dart';
import 'package:matrix/matrix.dart';

class UpdateGroupChatInteractor {
  Stream<Either<Failure, Success>> execute({
    required Room room,
    required Client client,
    Uri? avatarUrl,
    String? displayName,
    String? description,
    bool isDeleteAvatar = false,
  }) async* {
    yield const Right(UpdateGroupChatLoading());

    if (avatarUrl != null || isDeleteAvatar) {
      try {
        await client.setRoomStateWithKey(
          room.id,
          EventTypes.RoomAvatar,
          '',
          {
            'url': isDeleteAvatar ? null : avatarUrl.toString(),
          },
        );
        yield Right(UpdateAvatarGroupChatSuccess(isDeleteAvatar));
      } catch (e) {
        Logs().e('UpdateGroupChatInteractor::_updateAvatarForRoom(): $e');
        yield Left(UpdateGroupAvatarFailure(e));
        return;
      }
    }
    if (displayName != null && displayName != room.name) {
      try {
        await client.setRoomStateWithKey(
          room.id,
          EventTypes.RoomName,
          '',
          {
            'name': displayName,
          },
        );
        yield const Right(UpdateDisplayNameGroupChatSuccess());
      } catch (e) {
        Logs().e('UpdateGroupChatInteractor::_updateDisplayNameForRoom(): $e');
        yield Left(UpdateGroupDisplayNameFailure(e));
        return;
      }
    }

    if (description != null && description != room.topic) {
      try {
        await client.setRoomStateWithKey(
          room.id,
          EventTypes.RoomTopic,
          '',
          {
            'topic': description,
          },
        );
        yield const Right(UpdateDescriptionGroupChatSuccess());
      } catch (e) {
        Logs().e('UpdateGroupChatInteractor::_updateDescriptionForRoom(): $e');
        yield Left(UpdateGroupDescriptionFailure(e));
        return;
      }
    }
  }
}
