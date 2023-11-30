import 'package:json_annotation/json_annotation.dart';

part 'keychain_sharing_session.g.dart';

@JsonSerializable()
class KeychainSharingSession {
  String accessToken;
  String? refreshToken;
  String? oidcData;
  String? slidingSyncProxy;
  String userId;
  String deviceId;
  String homeserverUrl;

  KeychainSharingSession({
    required this.accessToken,
    this.refreshToken,
    this.oidcData,
    this.slidingSyncProxy,
    required this.userId,
    required this.deviceId,
    required this.homeserverUrl,
  });

  factory KeychainSharingSession.fromJson(Map<String, dynamic> json) =>
      _$KeychainSharingSessionFromJson(json);

  Map<String, dynamic> toJson() => _$KeychainSharingSessionToJson(this);
}
