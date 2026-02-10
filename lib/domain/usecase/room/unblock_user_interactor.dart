import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/data/network/exception/ignore_user_exceptions.dart';
import 'package:fluffychat/domain/app_state/room/unblock_user_state.dart';
import 'package:matrix/matrix.dart';

class UnblockUserInteractor {
  Stream<Either<Failure, Success>> execute({
    required Client client,
    required String userId,
  }) async* {
    try {
      yield Right(UnblockUserLoading());
      if (!userId.isValidMatrixId) {
        throw NotValidMxidException();
      }
      if (!client.ignoredUsers.contains(userId)) {
        throw NotInTheIgnoreListException();
      }
      await client.setAccountData(client.userID!, 'm.ignored_user_list', {
        'ignored_users': Map.fromEntries(
          (client.ignoredUsers..remove(userId)).map((key) => MapEntry(key, {})),
        ),
      });
      yield const Right(UnblockUserSuccess());
    } on MatrixException catch (e) {
      if (e.error == MatrixError.M_FORBIDDEN) {
        yield const Left(NoPermissionForUnblockFailure());
      }
    } catch (error) {
      if (error is NotValidMxidException) {
        yield const Left(NotValidMxidUnblockFailure());
      }
      if (error is NotInTheIgnoreListException) {
        yield const Left(NotInTheIgnoreListFailure());
      }
      yield Left(UnblockUserFailure(exception: error));
    }
  }
}
