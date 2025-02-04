import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_lookup_mxid_response.dart';

class FederationIdentityLookupInitial extends Initial {
  const FederationIdentityLookupInitial() : super();

  @override
  List<Object?> get props => [];
}

class FederationIdentityLookupLoading extends Success {
  const FederationIdentityLookupLoading();

  @override
  List<Object?> get props => [];
}

class FederationIdentityLookupSuccess extends Success {
  const FederationIdentityLookupSuccess({
    required this.federationLookupMxidResponse,
  });

  final FederationLookupMxidResponse federationLookupMxidResponse;

  @override
  List<Object?> get props => [];
}

class FederationIdentityLookupFailure extends Failure {
  final dynamic exception;

  const FederationIdentityLookupFailure({required this.exception});

  @override
  List<Object?> get props => [exception];
}

class FederationIdentityCalculationHashesEmpty extends Failure {
  const FederationIdentityCalculationHashesEmpty();

  @override
  List<Object?> get props => [];
}

class FederationIdentityGetTokenFailure extends Failure {
  const FederationIdentityGetTokenFailure();

  @override
  List<Object?> get props => [];
}
