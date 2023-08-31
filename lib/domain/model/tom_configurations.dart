import 'package:equatable/equatable.dart';
import 'package:fluffychat/domain/model/tom_server_information.dart';
import 'package:matrix/matrix.dart';

class ToMConfigurations with EquatableMixin {
  final ToMServerInformation tomServerInformation;
  final IdentityServerInformation? identityServerInformation;
  final String? authUrl;
  final LoginType? loginType;

  ToMConfigurations({
    required this.tomServerInformation,
    this.identityServerInformation,
    this.authUrl,
    this.loginType,
  });

  @override
  List<Object?> get props =>
      [tomServerInformation, identityServerInformation, authUrl, loginType];
}
