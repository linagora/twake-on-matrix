import 'package:equatable/equatable.dart';

class FederationLookUpArgument with EquatableMixin {
  final String homeServerUrl;
  final String federationUrl;
  final String withMxId;
  final String withAccessToken;

  FederationLookUpArgument({
    required this.homeServerUrl,
    required this.federationUrl,
    required this.withMxId,
    required this.withAccessToken,
  });

  @override
  List<Object?> get props => [
        homeServerUrl,
        federationUrl,
        withMxId,
        withAccessToken,
      ];
}
