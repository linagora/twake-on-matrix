import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/room/invite_user_state.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/domain/usecase/room/invite_user_interactor.dart';
import 'package:fluffychat/domain/usecase/room/unban_users_interactor.dart';
import 'package:matrix/matrix.dart';

class UnbanAndInviteUsersInteractor {
  const UnbanAndInviteUsersInteractor({
    required this.unbanUsersInteractor,
    required this.inviteUserInteractor,
  });

  final UnbanUsersInteractor unbanUsersInteractor;
  final InviteUserInteractor inviteUserInteractor;

  Stream<Either<Failure, Success>> execute({
    required Room room,
    required List<String> userIds,
  }) async* {
    if (userIds.isEmpty) {
      yield const Left(InviteWithNoUserFailure());
      return;
    }
    await unbanUsersInteractor
        .execute(
          users: room.getBannedMembers().where(
            (user) => userIds.contains(user.id),
          ),
        )
        .last;
    yield* inviteUserInteractor.execute(
      matrixClient: room.client,
      roomId: room.id,
      userIds: userIds,
    );
  }
}
