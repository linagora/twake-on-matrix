import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/room/set_permission_level_state.dart';
import 'package:matrix/matrix.dart';

class SetPermissionLevelInteractor {
  Stream<Either<Failure, Success>> execute({
    required Map<User, int> userPermissionLevels,
  }) async* {
    try {
      yield Right(SetPermissionLevelLoading());

      for (final entry in userPermissionLevels.entries) {
        final user = entry.key;
        final level = entry.value;

        await user.setPower(level);
      }

      yield const Right(SetPermissionLevelSuccess());
    } on MatrixException catch (e) {
      if (e.error == MatrixError.M_FORBIDDEN) {
        yield const Left(
          NoPermissionFailure(),
        );
      }
    } catch (error) {
      yield Left(
        SetPermissionLevelFailure(
          exception: error,
        ),
      );
    }
  }
}
