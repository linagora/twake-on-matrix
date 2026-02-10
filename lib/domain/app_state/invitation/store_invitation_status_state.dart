import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/success.dart';

class StoreInvitationStatusInitial extends Initial {
  const StoreInvitationStatusInitial() : super();

  @override
  List<Object?> get props => [];
}

class StoreInvitationStatusLoadingState extends Success {
  const StoreInvitationStatusLoadingState() : super();

  @override
  List<Object?> get props => [];
}

class StoreInvitationStatusSuccessState extends Success {
  final String contactId;
  final String userId;
  final String invitationId;

  const StoreInvitationStatusSuccessState({
    required this.contactId,
    required this.userId,
    required this.invitationId,
  });

  @override
  List<Object?> get props => [contactId, userId, invitationId];
}

class StoreInvitationStatusFailureState extends Failure {
  final dynamic exception;
  final String? message;
  final String contactId;
  final String userId;
  final String invitationId;

  const StoreInvitationStatusFailureState({
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
