import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/datasource/activity/activity_reactions_datasource.dart';
import 'package:twake_chat/domain/model/activity/activity_item.dart';
import 'package:twake_chat/utils/activity/activity_reactions_store.dart';

class ActivityReactionsDatasourceImpl implements ActivityReactionsDatasource {
  const ActivityReactionsDatasourceImpl(this._client);

  final Client? _client;

  @override
  Stream<List<ActivityItem>> watchReactions() async* {
    final store = _client?.activityReactionsStore;
    if (store == null) {
      yield const [];
      return;
    }
    yield store.reactions;
    yield* store.changes;
  }
}
