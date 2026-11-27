import 'package:twake_chat/domain/profile/entities/account_profile.dart';
import 'package:twake_chat/domain/profile/entities/avatar_upload.dart';

abstract class ProfileRepository {
  /// Null when the user is unknown or cannot be reached; with [fresh], also
  /// when the server does not answer.
  Future<AccountProfile?> fetchProfile(String userId, {bool fresh = false});

  /// The profile of every logged-in account, in the order they were added.
  Future<List<AccountProfile>> fetchAccountProfiles();

  /// Returns the content URI of the uploaded image.
  Future<Uri> uploadAvatar(AvatarUpload avatar);

  /// A null [avatarUrl] removes the avatar.
  Future<void> saveOwnAvatar(Uri? avatarUrl);

  Future<void> saveOwnDisplayName(String displayName);

  /// Tells the other screens of the app that the own profile changed.
  void announceOwnProfile(AccountProfile profile);
}
