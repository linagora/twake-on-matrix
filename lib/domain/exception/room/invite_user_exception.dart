import 'package:equatable/equatable.dart';

/// Base exception for invite user operations
abstract class InviteUserException extends Equatable implements Exception {
  const InviteUserException();
}

/// Exception thrown when some users failed to be invited
class InviteUserPartialFailureException extends InviteUserException {
  final Map<String, Exception> failedUsers;

  const InviteUserPartialFailureException({
    required this.failedUsers,
  });

  @override
  List<Object?> get props => [failedUsers];
}
