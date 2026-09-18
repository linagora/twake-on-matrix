import 'package:twake_chat/data/datasource/feed/feed_datasource.dart';
import 'package:twake_chat/domain/repository/feed/feed_repository.dart';

class FeedRepositoryImpl implements FeedRepository {
  const FeedRepositoryImpl(this._feedDatasource);

  final FeedDatasource _feedDatasource;

  @override
  Future<String> createFeed({String? name, String? avatarUrl}) =>
      _feedDatasource.createFeed(name: name, avatarUrl: avatarUrl);
}
