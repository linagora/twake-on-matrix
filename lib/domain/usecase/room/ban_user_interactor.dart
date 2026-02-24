import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/default_power_level_member.dart';
import 'package:fluffychat/domain/app_state/room/ban_user_state.dart';
import 'package:matrix/matrix.dart';

class BanUserInteractor {
  Stream<Either<Failure, Success>> execute({required User user}) async* {
    try {
      yield Right(BanUserLoading());

      if (!user.canBan) {
        yield const Left(NoPermissionForBanFailure());
        return;
      }

      await _reducePowerLevelIfNeeded(user);

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

  /// Reduces the power level of a user to member level before banning.
  ///
  /// This is a best-effort operation. If it fails, the error is logged
  /// but the ban operation continues. This prevents issues when banning
  /// users with elevated privileges.
  Future<void> _reducePowerLevelIfNeeded(User user) async {
    if (user.powerLevel <= DefaultPowerLevelMember.member.powerLevel) {
      return;
    }

    final powerLevelEvent = user.room.getState(EventTypes.RoomPowerLevels);

    // Skip power level reduction if state is null to avoid overwriting
    // server data
    if (powerLevelEvent == null) {
      return;
    }

    try {
      final powerMap = Map<String, dynamic>.from(powerLevelEvent.content);
      final usersMap = Map<String, dynamic>.from(
        powerMap['users'] as Map<String, dynamic>? ?? {},
      );
      powerMap['users'] = usersMap;

      usersMap[user.id] = DefaultPowerLevelMember.member.powerLevel;

      await user.room.client.setRoomStateWithKey(
        user.room.id,
        EventTypes.RoomPowerLevels,
        '',
        powerMap,
      );
    } catch (e) {
      Logs().w(
        'Failed to reduce power level for ${user.id} in room ${user.room.id}, proceeding with ban anyway',
        e,
      );
    }
  }
}
