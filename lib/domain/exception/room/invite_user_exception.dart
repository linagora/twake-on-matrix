import 'package:equatable/equatable.dart';

/// Base exception for invite user operations
abstract class InviteUserException extends Equatable implements Exception {
  final String userId;
  final String? message;

  const InviteUserException({required this.userId, this.message});

  @override
  List<Object?> get props => [userId, message];
}

/// Exception thrown when user was banned from the room
class UserBannedException extends InviteUserException {
  const UserBannedException({required super.userId, super.message});
}

/// Exception thrown for all other invite errors
class GenericInviteException extends InviteUserException {
  const GenericInviteException({required super.userId, super.message});
}

/// Exception thrown when some users failed to be invited
class InviteUserPartialFailureException extends Equatable implements Exception {
  final Map<String, InviteUserException> failedUsers;

  InviteUserPartialFailureException({required this.failedUsers});

  @override
  List<Object?> get props => [failedUsers];

  /// Get all banned users
  late final Map<String, UserBannedException> bannedUsers = Map.fromEntries(
    failedUsers.entries
        .where((e) => e.value is UserBannedException)
        .map((e) => MapEntry(e.key, e.value as UserBannedException)),
  );

  /// Get all other failed users (non-banned)
  late final Map<String, GenericInviteException> otherFailedUsers =
      Map.fromEntries(
        failedUsers.entries
            .where((e) => e.value is GenericInviteException)
            .map((e) => MapEntry(e.key, e.value as GenericInviteException)),
      );
}
