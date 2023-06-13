import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/room/set_room_avatar_failed.dart';
import 'package:fluffychat/domain/app_state/room/set_room_avatar_success.dart';
import 'package:matrix/matrix.dart';

class SetRoomAvatarInteractor {
  Stream<Either<Failure, Success>> execute(Client matrixClient, String roomId, MatrixFile? newAvatar) async* {
    try {
      final setAvatarEventId = await matrixClient.getRoomById(roomId)!.setAvatar(newAvatar);

      yield Right(SetRoomAvatarSuccess(roomAvatarEventId: setAvatarEventId));
    } catch (exception) {
      yield Left(SetRoomAvatarFailed(exception: exception));
    }
  }
}