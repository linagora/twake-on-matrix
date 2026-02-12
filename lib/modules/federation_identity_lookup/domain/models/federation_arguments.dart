import 'package:equatable/equatable.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_contact.dart';
import 'package:fluffychat/modules/federation_identity_request_token/domain/models/federation_token_information.dart';

class FederationArguments with EquatableMixin {
  final String federationUrl;

  final FederationTokenInformation tokenInformation;

  final Map<String, FederationContact> contactMaps;

  FederationArguments({
    required this.federationUrl,
    required this.tokenInformation,
    required this.contactMaps,
  });

  @override
  List<Object?> get props => [federationUrl, tokenInformation, contactMaps];
}
