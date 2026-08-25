import 'package:dartz/dartz.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/data/network/exception/ignore_user_exceptions.dart';
import 'package:twake_chat/domain/app_state/room/block_user_state.dart';
import 'package:matrix/matrix.dart';

class BlockUserInteractor {
  Stream<Either<Failure, Success>> execute({
    required Client client,
    required String userId,
  }) async* {
    try {
      yield Right(BlockUserLoading());
      if (!userId.isValidMatrixId) {
        throw NotValidMxidException();
      }
      await client.setAccountData(client.userID!, 'm.ignored_user_list', {
        'ignored_users': Map.fromEntries(
          (client.ignoredUsers..add(userId)).map((key) => MapEntry(key, {})),
        ),
      });

      yield const Right(BlockUserSuccess());
    } on MatrixException catch (e) {
      if (e.error == MatrixError.M_FORBIDDEN) {
        yield const Left(NoPermissionForBlockFailure());
      }
    } catch (error) {
      if (error is NotValidMxidException) {
        yield const Left(NotValidMxidBlockFailure());
      }
      yield Left(BlockUserFailure(exception: error));
    }
  }
}
