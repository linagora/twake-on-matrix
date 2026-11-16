import 'package:twake_chat/domain/model/activity/activity_item.dart';

abstract class ActivityDatasource {
  Stream<List<ActivityItem>> watchActivity();

  Stream<int> watchUnreadMentionCount();

  Future<void> markRoomRead(String roomId);
}
