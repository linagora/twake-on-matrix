import 'package:twake_chat/domain/keychain_sharing/keychain_sharing_session.dart';
import 'package:twake_chat/utils/string_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'keychain_sharing_restore_token.g.dart';

@JsonSerializable()
class KeychainSharingRestoreToken {
  final KeychainSharingSession session;
  String? pusherNotificationClientIdentifier;

  KeychainSharingRestoreToken({required this.session}) {
    pusherNotificationClientIdentifier = session.userId.sha256Hash;
  }

  factory KeychainSharingRestoreToken.fromJson(Map<String, dynamic> json) =>
      _$KeychainSharingRestoreTokenFromJson(json);

  Map<String, dynamic> toJson() => _$KeychainSharingRestoreTokenToJson(this);
}
