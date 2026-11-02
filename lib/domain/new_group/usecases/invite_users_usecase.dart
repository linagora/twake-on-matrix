import 'package:twake_chat/domain/exception/room/invite_user_exception.dart';
import 'package:twake_chat/domain/repository/new_group/new_group_repository.dart';

class InviteUsersUseCase {
  const InviteUsersUseCase(this._repository);

  final NewGroupRepository _repository;

  /// Invites every user even when some fail, then throws an
  /// [InviteUserPartialFailureException] listing the failures.
  Future<void> execute({
    required String roomId,
    required List<String> userIds,
  }) async {
    final failedUsers = <String, InviteUserException>{};
    for (final userId in userIds) {
      try {
        await _repository.inviteUser(roomId: roomId, userId: userId);
      } on InviteUserException catch (exception) {
        failedUsers[userId] = exception;
      }
    }
    if (failedUsers.isNotEmpty) {
      throw InviteUserPartialFailureException(failedUsers: failedUsers);
    }
  }
}
