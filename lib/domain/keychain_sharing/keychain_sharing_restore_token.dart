import 'package:twake_chat/domain/keychain_sharing/keychain_sharing_session.dart';
import 'package:twake_chat/utils/string_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'keychain_sharing_restore_token.g.dart';

@JsonSerializable()
class KeychainSharingRestoreToken {
  final KeychainSharingSession session;
  String? pusherNotificationClientIdentifier;

  /// Marks a session minted for the notification extension. The extension
  /// ignores any other session, such as the app's own one written by older
  /// versions, so it never takes over the app's device.
  final bool? dedicated;

  KeychainSharingRestoreToken({required this.session, this.dedicated}) {
    pusherNotificationClientIdentifier = session.userId.sha256Hash;
  }

  factory KeychainSharingRestoreToken.fromJson(Map<String, dynamic> json) =>
      _$KeychainSharingRestoreTokenFromJson(json);

  Map<String, dynamic> toJson() => _$KeychainSharingRestoreTokenToJson(this);
}
