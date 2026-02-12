import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/modules/federation_identity_request_token/domain/models/federation_token_information.dart';

class FederationIdentityRequestTokenInitial extends Initial {
  const FederationIdentityRequestTokenInitial() : super();

  @override
  List<Object?> get props => [];
}

class FederationIdentityRequestTokenSuccess extends Success {
  final FederationTokenInformation tokenInformation;

  const FederationIdentityRequestTokenSuccess({required this.tokenInformation});

  @override
  List<Object?> get props => [tokenInformation];
}

class FederationIdentityRequestTokenFailure extends Failure {
  final dynamic exception;

  const FederationIdentityRequestTokenFailure({required this.exception});

  @override
  List<Object?> get props => [exception];
}
