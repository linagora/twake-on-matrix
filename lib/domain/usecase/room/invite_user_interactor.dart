import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/room/invite_user_state.dart';
import 'package:matrix/matrix.dart';

class InviteUserInteractor {
  static const int _maxRetries = 3;

  Stream<Either<Failure, Success>> execute({
    required Client matrixClient,
    required String roomId,
    String? groupName,
    required List<String> userIds,
  }) async* {
    yield Right(InviteUserLoading());

    final failedUsers = <String, Exception>{};

    for (final userId in userIds) {
      try {
        await _inviteUserWithRetry(
          matrixClient: matrixClient,
          roomId: roomId,
          userId: userId,
        );
      } catch (exception) {
        failedUsers[userId] = exception as Exception;
        Logs().e(
          'InviteUserInteractor::execute: Failed to invite user $userId after all retries',
          exception,
        );
      }
    }

    if (failedUsers.isNotEmpty) {
      yield Left(
        InviteUserFailed(
          exception: failedUsers,
        ),
      );
    } else {
      yield Right(
        InviteUserSuccess(
          roomId: roomId,
          groupName: groupName,
        ),
      );
    }
  }

  Future<void> _inviteUserWithRetry({
    required Client matrixClient,
    required String roomId,
    required String userId,
  }) async {
    int attempt = 0;

    while (attempt < _maxRetries) {
      try {
        attempt++;
        await matrixClient.inviteUser(
          roomId,
          userId,
        );
        return;
      } catch (exception) {
        Logs().e(
          'InviteUserInteractor::_inviteUserWithRetry: Failed to invite user $userId (attempt $attempt/$_maxRetries)',
          exception,
        );

        if (attempt >= _maxRetries) {
          Logs().e(
            'InviteUserInteractor::_inviteUserWithRetry: Max retries reached for user $userId',
          );
          rethrow;
        }
      }
    }
  }
}
