import 'package:equatable/equatable.dart';
import 'package:fluffychat/domain/model/tom_server_information.dart';
import 'package:matrix/matrix.dart';

class ToMConfigurations with EquatableMixin {
  final ToMServerInformation tomServerInformation;
  final IdentityServerInformation? identityServerInformation;

  ToMConfigurations({
    required this.tomServerInformation,
    this.identityServerInformation,
  });

  @override
  List<Object?> get props => [tomServerInformation, identityServerInformation];
}