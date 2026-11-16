import 'package:twake_chat/domain/model/activity/activity_item.dart';

/// The mentions of the user, rooms and threads, read from the server.
abstract class ActivityMentionsRepository {
  /// Newest first. Throws when the server cannot be reached.
  Future<List<ActivityItem>> getMentions();
}
