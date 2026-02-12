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
  final String userId;
  final String contactId;

  const HiveDeleteInvitationStatusSuccessState({
    required this.userId,
    required this.contactId,
  });

  @override
  List<Object?> get props => [userId, contactId];
}

class HiveDeleteInvitationStatusFailureState extends Failure {
  final dynamic exception;
  final String? message;
  final String userId;
  final String contactId;

  const HiveDeleteInvitationStatusFailureState({
    required this.exception,
    this.message,
    required this.userId,
    required this.contactId,
  });

  @override
  List<Object?> get props => [exception, message, userId, contactId];
}
