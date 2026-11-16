import 'package:twake_chat/domain/model/activity/activity_item.dart';

abstract class ActivityReactionsDatasource {
  Stream<List<ActivityItem>> watchReactions();
}
