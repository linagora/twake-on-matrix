import 'package:twake_chat/domain/profile/entities/account_profile.dart';
import 'package:twake_chat/domain/profile/exceptions/profile_exception.dart';
import 'package:twake_chat/domain/profile/repositories/profile_repository.dart';

final class RemoveOwnAvatarUseCase {
  const RemoveOwnAvatarUseCase(this._repository);

  final ProfileRepository _repository;

  /// Returns [current] without its avatar.
  Future<AccountProfile> execute(AccountProfile current) async {
    try {
      await _repository.saveOwnAvatar(null);
      final saved = current.copyWith(avatarUrl: null);
      _repository.announceOwnProfile(saved);
      return saved;
    } on Exception catch (e, s) {
      Error.throwWithStackTrace(RemoveOwnAvatarException(e), s);
    }
  }
}
