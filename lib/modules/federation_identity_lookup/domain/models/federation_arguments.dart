import 'package:equatable/equatable.dart';
import 'package:fluffychat/modules/federation_identity_request_token/domain/models/federation_token_information.dart';

class FederationArguments with EquatableMixin {
  final String federationUrl;

  final FederationTokenInformation tokenInformation;

  final Set<String>? phoneNumbers;

  final Set<String>? emailAddresses;

  FederationArguments({
    required this.federationUrl,
    required this.tokenInformation,
    this.phoneNumbers,
    this.emailAddresses,
  });

  @override
  List<Object?> get props => [
        federationUrl,
        tokenInformation,
        phoneNumbers,
        emailAddresses,
      ];
}
