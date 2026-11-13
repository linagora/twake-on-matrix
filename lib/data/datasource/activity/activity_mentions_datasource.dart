import 'package:twake_chat/domain/model/activity/activity_item.dart';

abstract class ActivityMentionsDatasource {
  Future<List<ActivityItem>> getMentions();
}
