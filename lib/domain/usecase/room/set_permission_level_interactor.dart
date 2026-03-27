import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/room/set_permission_level_state.dart';
import 'package:matrix/matrix.dart';

class SetPermissionLevelInteractor {
  /// Set the permission level for a list of users in a room
  /// [room] The room in which to set the permission levels
  /// [userPermissionLevels] A map of users and their corresponding permission levels to set
  ///
  Stream<Either<Failure, Success>> execute({
    required Room room,
    required Map<User, int> userPermissionLevels,
  }) async* {
    try {
      yield Right(SetPermissionLevelLoading());

      final powerMap = Map<String, dynamic>.from(
        room.getState(EventTypes.RoomPowerLevels)?.content ??
            const <String, dynamic>{},
      );
      final usersMap = Map<String, dynamic>.from(
        powerMap['users'] as Map? ?? const <String, dynamic>{},
      );
      powerMap['users'] = usersMap;

      userPermissionLevels.forEach((User user, int level) {
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
      } else {
        yield Left(SetPermissionLevelFailure(exception: e));
      }
    } catch (error) {
      yield Left(SetPermissionLevelFailure(exception: error));
    }
  }
}
