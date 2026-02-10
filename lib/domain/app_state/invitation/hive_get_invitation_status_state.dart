import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/success.dart';

class HiveGetInvitationStatusInitial extends Initial {
  const HiveGetInvitationStatusInitial() : super();

  @override
  List<Object?> get props => [];
}

class HiveGetInvitationStatusLoadingState extends Success {
  final String contactId;
  final String userId;

  const HiveGetInvitationStatusLoadingState({
    required this.contactId,
    required this.userId,
  });

  @override
  List<Object?> get props => [contactId, userId];
}

class HiveGetInvitationStatusSuccessState extends Success {
  final String contactId;
  final String invitationId;

  const HiveGetInvitationStatusSuccessState({
    required this.contactId,
    required this.invitationId,
  });

  @override
  List<Object?> get props => [contactId, invitationId];
}

class HiveGetInvitationStatusFailureState extends Failure {
  final dynamic exception;
  final String contactId;
  final String userId;
  final String? message;

  const HiveGetInvitationStatusFailureState({
    required this.exception,
    this.message,
    required this.contactId,
    required this.userId,
  });

  @override
  List<Object?> get props => [exception, message, contactId, userId];
}
