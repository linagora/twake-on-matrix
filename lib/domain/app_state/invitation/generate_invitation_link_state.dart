import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/success.dart';

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
  final String link;

  const GenerateInvitationLinkSuccessState({
    required this.link,
  });

  @override
  List<Object?> get props => [link];
}

class GenerateInvitationLinkIsEmptyState extends Failure {
  const GenerateInvitationLinkIsEmptyState() : super();

  @override
  List<Object?> get props => [];
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
