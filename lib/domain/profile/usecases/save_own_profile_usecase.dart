import 'package:twake_chat/domain/profile/entities/account_profile.dart';
import 'package:twake_chat/domain/profile/entities/avatar_upload.dart';
import 'package:twake_chat/domain/profile/exceptions/profile_exception.dart';
import 'package:twake_chat/domain/profile/repositories/profile_repository.dart';

final class SaveOwnProfileUseCase {
  const SaveOwnProfileUseCase(this._repository);

  final ProfileRepository _repository;

  /// Returns [current] with the saved changes.
  Future<AccountProfile> execute(
    AccountProfile current, {
    String? displayName,
    AvatarUpload? avatar,
  }) async {
    try {
      final avatarUrl = avatar == null
          ? null
          : await _repository.uploadAvatar(avatar);
      if (avatarUrl != null) await _repository.saveOwnAvatar(avatarUrl);
      if (displayName != null) {
        await _repository.saveOwnDisplayName(displayName);
      }
      final saved = current.copyWith(
        displayName: displayName ?? current.displayName,
        avatarUrl: avatarUrl ?? current.avatarUrl,
      );
      _repository.announceOwnProfile(saved);
      return saved;
    } on Exception catch (e, s) {
      Error.throwWithStackTrace(SaveOwnProfileException(e), s);
    }
  }
}
