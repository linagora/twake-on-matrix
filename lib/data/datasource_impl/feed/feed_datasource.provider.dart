import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource/feed/feed_datasource.dart';
import 'package:twake_chat/data/datasource_impl/feed/feed_datasource_impl.dart';
import 'package:twake_chat/providers/matrix_client_provider.dart';

part 'feed_datasource.provider.g.dart';

@riverpod
FeedDatasource feedDatasource(Ref ref) =>
    FeedDatasourceImpl(ref.watch(matrixClientProvider));
