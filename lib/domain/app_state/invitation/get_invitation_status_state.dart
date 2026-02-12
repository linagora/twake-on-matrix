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
  final String contactId;
  final String userId;
  final String invitationId;

  const GetInvitationStatusEmptyState({
    required this.contactId,
    required this.userId,
    required this.invitationId,
  }) : super();

  @override
  List<Object?> get props => [contactId, userId, invitationId];
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
  final String contactId;
  final String userId;
  final String invitationId;

  const GetInvitationStatusFailureState({
    required this.exception,
    this.message,
    required this.contactId,
    required this.userId,
    required this.invitationId,
  });

  @override
  List<Object?> get props => [
    exception,
    message,
    contactId,
    userId,
    invitationId,
  ];
}
