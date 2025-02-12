import 'package:equatable/equatable.dart';

class FederationTokenRequest with EquatableMixin {
  final String federationUrl;
  final String mxid;
  final String token;

  FederationTokenRequest({
    required this.federationUrl,
    required this.mxid,
    required this.token,
  });

  @override
  List<Object?> get props => [
        federationUrl,
        mxid,
        token,
      ];
}
