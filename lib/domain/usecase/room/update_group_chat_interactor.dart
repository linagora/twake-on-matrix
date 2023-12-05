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
    MatrixFile? avatar,
    String? displayName,
    String? description,
    bool isDeleteAvatar = false,
  }) async* {
    yield const Right(UpdateGroupChatLoading());
    try {
      Logs().d(
        'UpdateGroupChatInteractor::execute(): Avatar - ${avatar?.name} - displayName - $displayName - description - $description',
      );

      Future.wait([
        if (isDeleteAvatar) room.setAvatar(null),
        if (avatar != null) room.setAvatar(avatar),
        if (displayName != null) room.setName(displayName),
        if (description != null) room.setDescription(description),
      ]);

      yield Right(
        UpdateGroupChatSuccess(
          displayName: displayName,
          roomAvatarFile: avatar,
          description: description,
          isDeleteAvatar: isDeleteAvatar,
        ),
      );
    } catch (e) {
      Logs().d(
        'UpdateGroupChatInteractor::execute(): Exception - $e}',
      );
      yield Left(UpdateGroupChatFailure(e));
    }
  }
}
