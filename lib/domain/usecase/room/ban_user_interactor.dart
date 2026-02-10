import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
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
