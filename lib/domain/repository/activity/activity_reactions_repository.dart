import 'package:twake_chat/domain/model/activity/activity_item.dart';

/// The reactions of the others to the messages of the user.
abstract class ActivityReactionsRepository {
  /// The reactions seen by the client in this session, the newest first, 50
  /// at most: now, then at each change.
  Stream<List<ActivityItem>> watchReactions();
}
