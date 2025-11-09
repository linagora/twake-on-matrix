import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';

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

class InviteUserFailed extends Failure {
  final dynamic exception;

  const InviteUserFailed({required this.exception});

  @override
  List<Object?> get props => [exception];
}
