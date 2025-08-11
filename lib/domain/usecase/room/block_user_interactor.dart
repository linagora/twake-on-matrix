import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/room/block_user_state.dart';
import 'package:matrix/matrix.dart';

class BlockUserInteractor {
  Stream<Either<Failure, Success>> execute({
    required Client client,
    required String userId,
  }) async* {
    try {
      yield Right(BlockUserLoading());

      await client.ignoreUser(userId);

      yield const Right(BlockUserSuccess());
    } on MatrixException catch (e) {
      if (e.error == MatrixError.M_FORBIDDEN) {
        yield const Left(
          NoPermissionForBlockFailure(),
        );
      }
    } catch (error) {
      yield Left(
        BlockUserFailure(
          exception: error,
        ),
      );
    }
  }
}
