import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/success.dart';

class HiveDeleteInvitationStatusInitial extends Initial {
  const HiveDeleteInvitationStatusInitial() : super();

  @override
  List<Object?> get props => [];
}

class HiveDeleteInvitationStatusLoadingState extends Success {
  const HiveDeleteInvitationStatusLoadingState() : super();

  @override
  List<Object?> get props => [];
}

class HiveDeleteInvitationStatusSuccessState extends Success {
  const HiveDeleteInvitationStatusSuccessState();

  @override
  List<Object?> get props => [];
}

class HiveDeleteInvitationStatusFailureState extends Failure {
  final dynamic exception;
  final String? message;

  const HiveDeleteInvitationStatusFailureState({
    required this.exception,
    this.message,
  });

  @override
  List<Object?> get props => [
        exception,
        message,
      ];
}
