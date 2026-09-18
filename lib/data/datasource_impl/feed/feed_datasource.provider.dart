import 'package:matrix/matrix.dart' show Client;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource/feed/feed_datasource.dart';
import 'package:twake_chat/data/datasource_impl/feed/feed_datasource_impl.dart';

part 'feed_datasource.provider.g.dart';

@riverpod
FeedDatasource feedDatasource(Ref ref, Client client) =>
    FeedDatasourceImpl(client);
