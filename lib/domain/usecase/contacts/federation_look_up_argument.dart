import 'package:fluffychat/domain/usecase/contacts/twake_look_up_argument.dart';

class FederationLookUpArgument extends TwakeLookUpArgument {
  final List<String> federationUrls;

  /// Queried directly only when absent from any `third_party_mappings` response.
  final String? identityServerUrl;
  final String withMxId;

  FederationLookUpArgument({
    required super.homeServerUrl,
    required this.federationUrls,
    this.identityServerUrl,
    required this.withMxId,
    required super.withAccessToken,
  });

  @override
  List<Object?> get props => [
    homeServerUrl,
    federationUrls,
    identityServerUrl,
    withMxId,
    withAccessToken,
  ];
}
