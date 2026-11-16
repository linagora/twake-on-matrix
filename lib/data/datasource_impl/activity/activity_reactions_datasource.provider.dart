import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource/activity/activity_reactions_datasource.dart';
import 'package:twake_chat/data/datasource_impl/activity/activity_reactions_datasource_impl.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

part 'activity_reactions_datasource.provider.g.dart';

@riverpod
ActivityReactionsDatasource activityReactionsDatasource(Ref ref) =>
    ActivityReactionsDatasourceImpl(ref.watch(activeMatrixClientProvider));
