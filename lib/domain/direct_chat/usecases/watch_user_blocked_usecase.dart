import 'package:twake_chat/domain/direct_chat/repositories/ignored_users_repository.dart';

class WatchUserBlockedUseCase {
  const WatchUserBlockedUseCase(this._repository);

  final IgnoredUsersRepository _repository;

  /// Emits whether [userId] is blocked, now and on every change; a blank id is
  /// never blocked.
  Stream<bool> execute(String userId) {
    if (userId.isEmpty) return Stream.value(false);
    return _repository.watchIsIgnored(userId).distinct();
  }
}
