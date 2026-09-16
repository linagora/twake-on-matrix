import 'package:matrix/matrix.dart' show Client;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource_impl/feed/feed_datasource.provider.dart';
import 'package:twake_chat/data/repository/feed/feed_repository_impl.dart';
import 'package:twake_chat/domain/repository/feed/feed_repository.dart';

part 'feed_repository.provider.g.dart';

@riverpod
FeedRepository feedRepository(Ref ref, Client client) =>
    FeedRepositoryImpl(ref.watch(feedDatasourceProvider(client)));
