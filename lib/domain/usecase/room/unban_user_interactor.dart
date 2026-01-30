import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/room/unban_user_state.dart';
import 'package:matrix/matrix.dart';

class UnbanUserInteractor {
  Stream<Either<Failure, Success>> execute({
    required User user,
  }) async* {
    try {
      yield Right(UnbanUserLoading());

      if (!user.canBan) {
        yield const Left(
          NoPermissionForUnbanFailure(),
        );
        return;
      }

      await user.unban();

      yield const Right(UnbanUserSuccess());
    } on MatrixException catch (e) {
      if (e.error == MatrixError.M_FORBIDDEN) {
        yield const Left(
          NoPermissionForUnbanFailure(),
        );
      }
    } catch (error) {
      yield Left(
        UnbanUserFailure(
          exception: error,
        ),
      );
    }
  }
}
