import 'package:twake_chat/domain/repository/activity/activity_repository.dart';

/// The unread mentions, now then at each change.
final class WatchUnreadMentionCountUseCase {
  const WatchUnreadMentionCountUseCase(this._repository);

  final ActivityRepository _repository;

  Stream<int> execute() => _repository.watchUnreadMentionCount();
}
