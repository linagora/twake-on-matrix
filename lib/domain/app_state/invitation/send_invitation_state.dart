import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/data/model/invitation/send_invitation_response.dart';

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

  const SendInvitationSuccessState({
    required this.sendInvitationResponse,
  });

  @override
  List<Object?> get props => [sendInvitationResponse];
}

class SendInvitationFailureState extends Failure {
  final dynamic exception;
  final String? message;

  const SendInvitationFailureState({
    required this.exception,
    this.message,
  });

  @override
  List<Object?> get props => [
        exception,
        message,
      ];
}
