import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/room/unblock_user_state.dart';
import 'package:matrix/matrix.dart';

class UnblockUserInteractor {
  Stream<Either<Failure, Success>> execute({
    required Client client,
    required String userId,
  }) async* {
    try {
      yield Right(UnblockUserLoading());
      await client.unignoreUser(userId);
      yield const Right(UnblockUserSuccess());
    } on MatrixException catch (e) {
      if (e.error == MatrixError.M_FORBIDDEN) {
        yield const Left(
          NoPermissionForUnblockFailure(),
        );
      }
    } catch (error) {
      yield Left(
        UnblockUserFailure(
          exception: error,
        ),
      );
    }
  }
}
