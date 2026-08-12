import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/initial.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/data/model/invitation/send_invitation_response.dart';

class SendInvitationInitial extends Initial {
  const SendInvitationInitial() : super();

  @override
  List<Object?> get props => [];
}

class SendInvitationLoadingState extends Success {
  const SendInvitationLoadingState() : super();

  @override
  List<Object?> get props => [];
}

class SendInvitationSuccessState extends Success {
  final SendInvitationResponse sendInvitationResponse;
  final String contactId;

  const SendInvitationSuccessState({
    required this.sendInvitationResponse,
    required this.contactId,
  });

  @override
  List<Object?> get props => [sendInvitationResponse, contactId];
}

class InvitationAlreadySentState extends Failure {
  const InvitationAlreadySentState() : super();

  @override
  List<Object?> get props => [];
}

class SendInvitationFailureState extends Failure {
  final dynamic exception;
  final String? message;

  const SendInvitationFailureState({required this.exception, this.message});

  @override
  List<Object?> get props => [exception, message];
}

class InvalidPhoneNumberFailureState extends Failure {
  const InvalidPhoneNumberFailureState() : super();

  @override
  List<Object?> get props => [];
}

class InvalidEmailFailureState extends Failure {
  const InvalidEmailFailureState() : super();

  @override
  List<Object?> get props => [];
}
