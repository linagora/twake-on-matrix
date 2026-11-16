import 'package:twake_chat/domain/model/activity/activity_item.dart';
import 'package:twake_chat/domain/repository/activity/activity_repository.dart';

/// The unread rooms and the followed threads, now then at each change.
final class WatchActivityUseCase {
  const WatchActivityUseCase(this._repository);

  final ActivityRepository _repository;

  Stream<List<ActivityItem>> execute() => _repository.watchActivity();
}
