import 'package:equatable/equatable.dart';
import 'package:fluffychat/data/model/federation_server/federation_server_information.dart';
import 'package:matrix/matrix.dart';

class FederationConfigurations with EquatableMixin {
  final FederationServerInformation fedServerInformation;
  final IdentityServerInformation? identityServerInformation;

  FederationConfigurations({
    required this.fedServerInformation,
    this.identityServerInformation,
  });

  @override
  List<Object?> get props => [fedServerInformation, identityServerInformation];
}
