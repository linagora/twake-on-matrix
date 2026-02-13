import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/default_power_level_member.dart';
import 'package:fluffychat/domain/app_state/room/ban_user_state.dart';
import 'package:matrix/matrix.dart';

class BanUserInteractor {
  Stream<Either<Failure, Success>> execute({
    required User user,
    required Room room,
  }) async* {
    try {
      yield Right(BanUserLoading());

      if (!user.canBan) {
        yield const Left(NoPermissionForBanFailure());
        return;
      }

      // Reduce power level to member before banning if user has elevated privileges
      // Note: This is a best-effort operation. If it fails, we still proceed with the ban.
      if (user.powerLevel > DefaultPowerLevelMember.member.powerLevel) {
        final powerLevelEvent = room.getState(EventTypes.RoomPowerLevels);

        // Skip power level reduction if state is null to avoid overwriting server data
        if (powerLevelEvent != null) {
          try {
            final powerMap = Map<String, dynamic>.from(powerLevelEvent.content);
            final usersMap = Map<String, dynamic>.from(
              powerMap['users'] as Map<String, dynamic>? ?? {},
            );
            powerMap['users'] = usersMap;

            usersMap[user.id] = DefaultPowerLevelMember.member.powerLevel;

            await room.client.setRoomStateWithKey(
              room.id,
              EventTypes.RoomPowerLevels,
              '',
              powerMap,
            );
          } catch (e) {
            // Log the error but don't block the ban operation
            Logs().w(
              'Failed to reduce power level for ${user.id} in room ${room.id}, proceeding with ban anyway',
              e,
            );
          }
        }
      }

      await user.ban();

      yield const Right(BanUserSuccess());
    } on MatrixException catch (e) {
      if (e.error == MatrixError.M_FORBIDDEN) {
        yield const Left(NoPermissionForBanFailure());
      } else {
        yield Left(BanUserFailure(exception: e));
      }
    } catch (error) {
      yield Left(BanUserFailure(exception: error));
    }
  }
}
