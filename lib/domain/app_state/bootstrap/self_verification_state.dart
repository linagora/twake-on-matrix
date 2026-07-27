import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:matrix/encryption.dart';

class StartSelfVerificationLoadingState extends Success {
  const StartSelfVerificationLoadingState() : super();

  @override
  List<Object?> get props => [];
}

class StartSelfVerificationSuccessState extends Success {
  final KeyVerification request;

  const StartSelfVerificationSuccessState({required this.request});

  @override
  List<Object?> get props => [request];
}

class StartSelfVerificationFailureState extends Failure {
  final dynamic exception;

  const StartSelfVerificationFailureState({required this.exception});

  @override
  List<Object?> get props => [exception];
}
