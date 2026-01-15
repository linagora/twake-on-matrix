import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/exception/room/invite_user_exception.dart';

class InviteUserInitial extends Success {
  @override
  List<Object?> get props => [];
}

class InviteUserLoading extends Success {
  @override
  List<Object?> get props => [];
}

class InviteUserSuccess extends Success {
  final String roomId;
  final String? groupName;

  const InviteUserSuccess({
    required this.roomId,
    this.groupName,
  });

  @override
  List<Object?> get props => [roomId, groupName];
}

class InviteUserSomeFailed extends Failure {
  final InviteUserPartialFailureException inviteUserPartialFailureException;

  const InviteUserSomeFailed({
    required this.inviteUserPartialFailureException,
  });

  @override
  List<Object?> get props => [inviteUserPartialFailureException];
}

class InviteWithNoUserFailure extends Failure {
  const InviteWithNoUserFailure();

  @override
  List<Object?> get props => [];
}
