import 'package:fluffychat/domain/usecase/contacts/twake_look_up_argument.dart';

class FederationLookUpArgument extends TwakeLookUpArgument {
  final String federationUrl;
  final String withMxId;

  FederationLookUpArgument({
    required super.homeServerUrl,
    required this.federationUrl,
    required this.withMxId,
    required super.withAccessToken,
  });

  @override
  List<Object?> get props => [
    homeServerUrl,
    federationUrl,
    withMxId,
    withAccessToken,
  ];
}
