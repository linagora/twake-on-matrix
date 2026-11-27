import 'package:twake_chat/data/contact/datasources/matrix_profile_datasource.dart';
import 'package:twake_chat/data/profile/datasources/account_profiles_datasource.dart';
import 'package:twake_chat/data/profile/datasources/own_profile_datasource.dart';
import 'package:twake_chat/domain/profile/entities/account_profile.dart';
import 'package:twake_chat/domain/profile/entities/avatar_upload.dart';
import 'package:twake_chat/domain/profile/repositories/profile_repository.dart';

final class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._profiles, this._accounts, this._own);

  final MatrixProfileDatasource _profiles;
  final AccountProfilesDatasource _accounts;
  final OwnProfileDatasource _own;

  @override
  Future<AccountProfile?> fetchProfile(
    String userId, {
    bool fresh = false,
  }) async {
    final profile = await _profiles.fetchProfile(userId, fresh: fresh);
    if (profile == null) return null;
    final avatarUrl = profile.avatarUrl;
    return AccountProfile(
      userId: userId,
      displayName: profile.displayName,
      avatarUrl: avatarUrl == null ? null : Uri.tryParse(avatarUrl),
    );
  }

  @override
  Future<List<AccountProfile>> fetchAccountProfiles() =>
      _accounts.fetchAccountProfiles();

  @override
  Future<Uri> uploadAvatar(AvatarUpload avatar) => _own.uploadAvatar(avatar);

  @override
  Future<void> saveOwnAvatar(Uri? avatarUrl) => _own.setAvatar(avatarUrl);

  @override
  Future<void> saveOwnDisplayName(String displayName) =>
      _own.setDisplayName(displayName);

  @override
  void announceOwnProfile(AccountProfile profile) => _own.announce(profile);
}
