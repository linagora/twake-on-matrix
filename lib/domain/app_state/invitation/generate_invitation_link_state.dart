import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/data/model/invitation/generate_invitation_link_response.dart';

class GenerateInvitationLinkInitial extends Initial {
  const GenerateInvitationLinkInitial() : super();

  @override
  List<Object?> get props => [];
}

class GenerateInvitationLinkLoadingState extends Success {
  const GenerateInvitationLinkLoadingState() : super();

  @override
  List<Object?> get props => [];
}

class GenerateInvitationLinkSuccessState extends Success {
  final GenerateInvitationLinkResponse generateInvitationLinkResponse;

  const GenerateInvitationLinkSuccessState({
    required this.generateInvitationLinkResponse,
  });

  @override
  List<Object?> get props => [generateInvitationLinkResponse];
}

class GenerateInvitationLinkFailureState extends Failure {
  final dynamic exception;
  final String? message;

  const GenerateInvitationLinkFailureState({
    required this.exception,
    this.message,
  });

  @override
  List<Object?> get props => [
        exception,
        message,
      ];
}
