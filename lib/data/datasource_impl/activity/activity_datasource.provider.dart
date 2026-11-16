import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource/activity/activity_datasource.dart';
import 'package:twake_chat/data/datasource_impl/activity/activity_datasource_impl.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

part 'activity_datasource.provider.g.dart';

@riverpod
ActivityDatasource activityDatasource(Ref ref) {
  final datasource = ActivityDatasourceImpl(
    ref.watch(activeMatrixClientProvider),
  );
  ref.onDispose(datasource.dispose);
  return datasource;
}
