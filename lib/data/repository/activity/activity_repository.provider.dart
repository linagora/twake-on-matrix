import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource_impl/activity/activity_datasource.provider.dart';
import 'package:twake_chat/data/repository/activity/activity_repository_impl.dart';
import 'package:twake_chat/domain/repository/activity/activity_repository.dart';

part 'activity_repository.provider.g.dart';

@riverpod
ActivityRepository activityRepository(Ref ref) =>
    ActivityRepositoryImpl(ref.watch(activityDatasourceProvider));
