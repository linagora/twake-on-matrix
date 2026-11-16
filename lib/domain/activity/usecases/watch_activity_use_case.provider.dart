import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/activity/activity_repository.provider.dart';
import 'package:twake_chat/domain/activity/usecases/watch_activity_use_case.dart';
import 'package:twake_chat/domain/model/activity/activity_item.dart';

part 'watch_activity_use_case.provider.g.dart';

@riverpod
WatchActivityUseCase watchActivityUseCase(Ref ref) =>
    WatchActivityUseCase(ref.watch(activityRepositoryProvider));

/// The unread rooms and the followed threads, at each change of the sync.
@riverpod
Stream<List<ActivityItem>> activityItems(Ref ref) =>
    ref.watch(watchActivityUseCaseProvider).execute();
