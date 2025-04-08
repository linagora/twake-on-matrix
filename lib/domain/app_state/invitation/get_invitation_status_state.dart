import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/data/model/invitation/invitation_status_response.dart';

class GetInvitationStatusInitial extends Initial {
  const GetInvitationStatusInitial() : super();

  @override
  List<Object?> get props => [];
}

class GetInvitationStatusLoadingState extends Success {
  const GetInvitationStatusLoadingState() : super();

  @override
  List<Object?> get props => [];
}

class GetInvitationStatusEmptyState extends Failure {
  const GetInvitationStatusEmptyState() : super();

  @override
  List<Object?> get props => [];
}

class GetInvitationStatusSuccessState extends Success {
  final InvitationStatusResponse invitationStatusResponse;

  const GetInvitationStatusSuccessState({
    required this.invitationStatusResponse,
  });

  @override
  List<Object?> get props => [invitationStatusResponse];
}

class GetInvitationStatusFailureState extends Failure {
  final dynamic exception;
  final String? message;

  const GetInvitationStatusFailureState({
    required this.exception,
    this.message,
  });

  @override
  List<Object?> get props => [
        exception,
        message,
      ];
}
