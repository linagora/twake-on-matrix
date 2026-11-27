import 'package:twake_chat/domain/profile/entities/account_profile.dart';
import 'package:twake_chat/domain/profile/entities/avatar_upload.dart';

abstract class OwnProfileDatasource {
  Future<Uri> uploadAvatar(AvatarUpload avatar);

  Future<void> setAvatar(Uri? avatarUrl);

  Future<void> setDisplayName(String displayName);

  /// Emits an in-app uploadAvatarEvent on the client's account data stream;
  /// nothing is sent to the server.
  void announce(AccountProfile profile);
}
