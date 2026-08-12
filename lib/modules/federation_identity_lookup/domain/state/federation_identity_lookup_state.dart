import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/modules/federation_identity_lookup/domain/models/federation_contact.dart';

class FederationIdentityLookupSuccess extends Success {
  const FederationIdentityLookupSuccess({required this.newContacts});

  final Map<String, FederationContact> newContacts;

  @override
  List<Object?> get props => [newContacts];
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

class NoFederationIdentityURL extends Failure {
  const NoFederationIdentityURL();

  @override
  List<Object?> get props => [];
}

class FederationIdentityRegisterAccountFailure extends Failure {
  const FederationIdentityRegisterAccountFailure({
    required this.identityServer,
  });

  final String identityServer;

  @override
  List<Object?> get props => [identityServer];
}

class FederationIdentityGetHashDetailsFailure extends Failure {
  const FederationIdentityGetHashDetailsFailure();

  @override
  List<Object?> get props => [];
}
