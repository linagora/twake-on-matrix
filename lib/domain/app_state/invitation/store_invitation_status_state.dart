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
  const StoreInvitationStatusSuccessState();

  @override
  List<Object?> get props => [];
}

class StoreInvitationStatusFailureState extends Failure {
  final dynamic exception;
  final String? message;

  const StoreInvitationStatusFailureState({
    required this.exception,
    this.message,
  });

  @override
  List<Object?> get props => [
        exception,
        message,
      ];
}
