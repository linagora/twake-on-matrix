import 'package:twake_chat/data/datasource/activity/activity_mentions_datasource.dart';
import 'package:twake_chat/domain/model/activity/activity_item.dart';
import 'package:twake_chat/domain/repository/activity/activity_mentions_repository.dart';

class ActivityMentionsRepositoryImpl implements ActivityMentionsRepository {
  const ActivityMentionsRepositoryImpl(this._datasource);

  final ActivityMentionsDatasource _datasource;

  @override
  Future<List<ActivityItem>> getMentions() => _datasource.getMentions();
}
