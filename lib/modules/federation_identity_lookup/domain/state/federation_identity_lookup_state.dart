import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_contact.dart';

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
    required this.newContacts,
  });

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
