import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/room/set_permission_level_state.dart';
import 'package:matrix/matrix.dart';

class SetPermissionLevelInteractor {
  Stream<Either<Failure, Success>> execute({
    required Room room,
    required Map<User, int> userPermissionLevels,
  }) async* {
    try {
      yield Right(SetPermissionLevelLoading());

      var powerMap = room.getState(EventTypes.RoomPowerLevels)?.content;
      if (powerMap is! Map<String, dynamic>) {
        powerMap = <String, dynamic>{};
      }
      final usersMap = powerMap['users'] ??= {};

      userPermissionLevels.forEach((user, level) {
        usersMap[user.id] = level;
      });

      await room.client.setRoomStateWithKey(
        room.id,
        EventTypes.RoomPowerLevels,
        '',
        powerMap,
      );

      yield const Right(SetPermissionLevelSuccess());
    } on MatrixException catch (e) {
      if (e.error == MatrixError.M_FORBIDDEN) {
        yield const Left(NoPermissionFailure());
      }
    } catch (error) {
      yield Left(SetPermissionLevelFailure(exception: error));
    }
  }
}
