import 'package:twake_chat/data/datasource/activity/activity_datasource.dart';
import 'package:twake_chat/domain/model/activity/activity_item.dart';
import 'package:twake_chat/domain/repository/activity/activity_repository.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  const ActivityRepositoryImpl(this._datasource);

  final ActivityDatasource _datasource;

  @override
  Stream<List<ActivityItem>> watchActivity() => _datasource.watchActivity();

  @override
  Stream<int> watchUnreadMentionCount() =>
      _datasource.watchUnreadMentionCount();

  @override
  Future<void> markRoomRead(String roomId) => _datasource.markRoomRead(roomId);
}
