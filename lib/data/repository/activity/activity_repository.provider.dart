import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource_impl/activity/activity_datasource.provider.dart';
import 'package:twake_chat/data/repository/activity/activity_repository_impl.dart';
import 'package:twake_chat/domain/model/activity/activity_item.dart';
import 'package:twake_chat/domain/repository/activity/activity_repository.dart';

part 'activity_repository.provider.g.dart';

@riverpod
ActivityRepository activityRepository(Ref ref) =>
    ActivityRepositoryImpl(ref.watch(activityDatasourceProvider));

/// The unread rooms and the followed threads, at each change of the sync.
@riverpod
Stream<List<ActivityItem>> activityItems(Ref ref) =>
    ref.watch(activityRepositoryProvider).watchActivity();

/// The unread mentions: the badge of the tab and the count of the title.
@riverpod
Stream<int> unreadMentionCount(Ref ref) =>
    ref.watch(activityRepositoryProvider).watchUnreadMentionCount();
