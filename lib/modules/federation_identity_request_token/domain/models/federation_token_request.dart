import 'package:equatable/equatable.dart';

class FederationTokenRequest with EquatableMixin {
  final String homeserverUrl;
  final String mxid;
  final String accessToken;

  FederationTokenRequest({
    required this.homeserverUrl,
    required this.mxid,
    required this.accessToken,
  });

  @override
  List<Object?> get props => [homeserverUrl, mxid, accessToken];
}
