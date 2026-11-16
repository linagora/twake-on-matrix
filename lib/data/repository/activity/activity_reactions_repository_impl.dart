import 'package:twake_chat/data/datasource/activity/activity_reactions_datasource.dart';
import 'package:twake_chat/domain/model/activity/activity_item.dart';
import 'package:twake_chat/domain/repository/activity/activity_reactions_repository.dart';

class ActivityReactionsRepositoryImpl implements ActivityReactionsRepository {
  const ActivityReactionsRepositoryImpl(this._datasource);

  final ActivityReactionsDatasource _datasource;

  @override
  Stream<List<ActivityItem>> watchReactions() => _datasource.watchReactions();
}
