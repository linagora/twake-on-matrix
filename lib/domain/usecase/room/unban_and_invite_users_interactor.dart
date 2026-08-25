import 'package:dartz/dartz.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/domain/app_state/room/invite_user_state.dart';
import 'package:twake_chat/domain/model/room/room_extension.dart';
import 'package:twake_chat/domain/usecase/room/invite_user_interactor.dart';
import 'package:twake_chat/domain/usecase/room/unban_users_interactor.dart';
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
