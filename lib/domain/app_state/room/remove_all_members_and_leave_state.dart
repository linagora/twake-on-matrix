import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/success.dart';

class RemoveAllMembersAndLeaveInitial extends Initial {
  @override
  List<Object?> get props => [];
}

class RemoveAllMembersAndLeaveLoading extends Success {
  const RemoveAllMembersAndLeaveLoading();

  @override
  List<Object?> get props => [];
}

class RemoveAllMembersCompleted extends Success {
  const RemoveAllMembersCompleted();

  @override
  List<Object?> get props => [];
}

class LeavingRoomState extends Success {
  const LeavingRoomState();

  @override
  List<Object?> get props => [];
}

class RemoveAllMembersAndLeaveSuccess extends Success {
  const RemoveAllMembersAndLeaveSuccess();

  @override
  List<Object?> get props => [];
}

class RemoveAllMembersAndLeaveFailure extends Failure {
  final dynamic exception;

  const RemoveAllMembersAndLeaveFailure({required this.exception});

  @override
  List<Object?> get props => [exception];
}

class NoPermissionToRemoveMembersFailure extends Failure {
  const NoPermissionToRemoveMembersFailure();

  @override
  List<Object?> get props => [];
}

class RoomNotFoundFailure extends Failure {
  const RoomNotFoundFailure();

  @override
  List<Object?> get props => [];
}

class LeaveRoomFailure extends Failure {
  final dynamic exception;

  const LeaveRoomFailure({required this.exception});

  @override
  List<Object?> get props => [exception];
}
