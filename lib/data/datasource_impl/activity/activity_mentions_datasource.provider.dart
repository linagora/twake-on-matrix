import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource/activity/activity_mentions_datasource.dart';
import 'package:twake_chat/data/datasource_impl/activity/activity_mentions_datasource_impl.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

part 'activity_mentions_datasource.provider.g.dart';

@riverpod
ActivityMentionsDatasource activityMentionsDatasource(Ref ref) =>
    ActivityMentionsDatasourceImpl(ref.watch(activeMatrixClientProvider));
