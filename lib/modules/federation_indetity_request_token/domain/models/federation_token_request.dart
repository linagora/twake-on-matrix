import 'package:equatable/equatable.dart';

class FederationTokenRequest with EquatableMixin {
  final String federationUrl;
  final String mxid;

  FederationTokenRequest({
    required this.federationUrl,
    required this.mxid,
  });

  @override
  List<Object?> get props => [
        federationUrl,
        mxid,
      ];
}
