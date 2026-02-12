import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/room/invite_user_state.dart';
import 'package:fluffychat/domain/exception/room/invite_user_exception.dart';
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

    final failedUsers = <String, InviteUserException>{};

    for (final userId in userIds) {
      try {
        await _inviteUserWithRetry(
          matrixClient: matrixClient,
          roomId: roomId,
          userId: userId,
        );
      } catch (exception) {
        failedUsers[userId] = _mapExceptionToInviteUserException(
          userId: userId,
          exception: exception,
        );
        Logs().e(
          'InviteUserInteractor::execute: Failed to invite user $userId after all retries',
          exception,
        );
      }
    }

    if (failedUsers.isNotEmpty) {
      yield Left(
        InviteUserSomeFailed(
          inviteUserPartialFailureException: InviteUserPartialFailureException(
            failedUsers: failedUsers,
          ),
        ),
      );
    } else {
      yield Right(InviteUserSuccess(roomId: roomId, groupName: groupName));
    }
  }

  /// Maps generic exceptions to specific InviteUserException types
  InviteUserException _mapExceptionToInviteUserException({
    required String userId,
    required Object exception,
  }) {
    if (exception is MatrixException) {
      final errorMessage = exception.errorMessage;

      // Check if it's a banned user error
      if (exception.errcode == 'M_BAD_STATE' &&
          errorMessage.contains('Cannot invite user who was banned')) {
        return UserBannedException(userId: userId, message: errorMessage);
      }

      // All other errors are generic
      return GenericInviteException(userId: userId, message: errorMessage);
    }

    // For non-Matrix exceptions
    return GenericInviteException(
      userId: userId,
      message: exception.toString(),
    );
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
        await matrixClient.inviteUser(roomId, userId);
        return;
      } catch (exception) {
        Logs().e(
          'InviteUserInteractor::_inviteUserWithRetry: Failed to invite user $userId (attempt $attempt/$_maxRetries)',
          exception,
        );

        // Only retry for MatrixException with M_LIMIT_EXCEEDED
        // All other exceptions should be rethrown immediately
        if (exception is! MatrixException ||
            exception.errcode != 'M_LIMIT_EXCEEDED') {
          Logs().e(
            'InviteUserInteractor::_inviteUserWithRetry: Non-retryable error for user $userId',
          );
          rethrow;
        }

        if (attempt >= _maxRetries) {
          Logs().e(
            'InviteUserInteractor::_inviteUserWithRetry: Max retries reached for user $userId',
          );
          rethrow;
        }

        // Handle rate limiting (M_LIMIT_EXCEEDED)
        final retryAfterMs = exception.retryAfterMs;
        if (retryAfterMs != null && retryAfterMs > 0) {
          Logs().d(
            'InviteUserInteractor::_inviteUserWithRetry: Rate limited. Waiting ${retryAfterMs}ms before retry',
          );
          await Future.delayed(Duration(milliseconds: retryAfterMs));
        }
      }
    }
  }
}
