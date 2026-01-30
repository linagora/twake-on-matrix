import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/room/unban_users_state.dart';
import 'package:fluffychat/domain/usecase/room/unban_user_interactor.dart';
import 'package:matrix/matrix.dart';

class UnbanUsersInteractor {
  const UnbanUsersInteractor({required this.unbanUserInteractor});

  final UnbanUserInteractor unbanUserInteractor;

  Stream<Either<Failure, Success>> execute({
    required Iterable<User> users,
  }) async* {
    yield Right(UnbanUsersLoading());

    final results = await Future.wait(
      users.map((user) async {
        final result = await unbanUserInteractor.execute(user: user).last;
        return MapEntry(user, result);
      }),
    );
    final Map<User, Failure> stillBannedUsers = {};
    for (final entry in results) {
      entry.value.fold(
        (failure) => stillBannedUsers[entry.key] = failure,
        (success) => {},
      );
    }
    if (stillBannedUsers.isEmpty) {
      yield const Right(UnbanUsersSuccess());
    } else {
      yield Left(UnbanUsersFailure(failures: stillBannedUsers));
    }
  }
}
