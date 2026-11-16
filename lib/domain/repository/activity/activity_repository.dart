import 'package:twake_chat/domain/model/activity/activity_item.dart';

/// The unread rooms and the followed threads of the account, from the sync
/// data held in memory.
abstract class ActivityRepository {
  /// The items now, then at each change.
  Stream<List<ActivityItem>> watchActivity();

  /// The unread mentions of the rooms and of their threads, now then at each
  /// change.
  Stream<int> watchUnreadMentionCount();

  /// Reads the main timeline of the room and its threads.
  Future<void> markRoomRead(String roomId);
}
