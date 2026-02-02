import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/room/remove_all_members_and_leave_state.dart';
import 'package:matrix/matrix.dart';

class RemoveAllMembersAndLeaveInteractor {
  Stream<Either<Failure, Success>> execute({
    required Room room,
  }) async* {
    try {
      yield const Right(RemoveAllMembersAndLeaveLoading());

      // Check if user has permission to kick members
      if (!room.canKick) {
        yield const Left(NoPermissionToRemoveMembersFailure());
        return;
      }

      // Get all members except the current user
      final allMembers = room.getParticipants([
        Membership.join,
        Membership.invite,
      ]);

      final membersToRemove = allMembers
          .where(
            (member) => member.id != room.client.userID,
          )
          .toList();

      if (membersToRemove.isEmpty) {
        Logs().d(
          'RemoveAllMembersAndLeaveInteractor::execute - No members to remove',
        );
        // If there are no members to remove, just leave the room
        yield const Right(RemoveAllMembersCompleted());
        await room.leave();
        yield const Right(RemoveAllMembersAndLeaveSuccess());
        return;
      }

      final totalCount = membersToRemove.length;

      Logs().d(
        'RemoveAllMembersAndLeaveInteractor::execute - Removing $totalCount members',
      );

      // Kick all members
      for (final member in membersToRemove) {
        try {
          // Check if the current user can kick this specific member
          if (room.canKick && room.ownPowerLevel > member.powerLevel) {
            await member.kick();

            Logs().d(
              'RemoveAllMembersAndLeaveInteractor::execute - Kicked member ${member.id}',
            );
          } else {
            Logs().w(
              'RemoveAllMembersAndLeaveInteractor::execute - Cannot kick member ${member.id} (insufficient power level)',
            );
          }
        } catch (e) {
          Logs().e(
            'RemoveAllMembersAndLeaveInteractor::execute - Failed to kick member ${member.id}',
            e,
          );
        }
      }

      // All members processed
      yield const Right(RemoveAllMembersCompleted());

      // Now leave the room
      Logs().d('RemoveAllMembersAndLeaveInteractor::execute - Leaving room');

      try {
        await room.leave();
        yield const Right(RemoveAllMembersAndLeaveSuccess());
      } catch (leaveError) {
        Logs().e(
          'RemoveAllMembersAndLeaveInteractor::execute - Failed to leave room',
          leaveError,
        );
        yield Left(LeaveRoomFailure(exception: leaveError));
      }
    } on MatrixException catch (e) {
      Logs().e(
        'RemoveAllMembersAndLeaveInteractor::execute - MatrixException',
        e,
      );
      if (e.error == MatrixError.M_FORBIDDEN) {
        yield const Left(NoPermissionToRemoveMembersFailure());
      } else {
        yield Left(RemoveAllMembersAndLeaveFailure(exception: e));
      }
    } catch (error) {
      Logs().e(
        'RemoveAllMembersAndLeaveInteractor::execute - Unexpected error',
        error,
      );
      yield Left(RemoveAllMembersAndLeaveFailure(exception: error));
    }
  }
}
