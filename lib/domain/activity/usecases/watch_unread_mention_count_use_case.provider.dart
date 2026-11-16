import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/activity/activity_repository.provider.dart';
import 'package:twake_chat/domain/activity/usecases/watch_unread_mention_count_use_case.dart';

part 'watch_unread_mention_count_use_case.provider.g.dart';

@riverpod
WatchUnreadMentionCountUseCase watchUnreadMentionCountUseCase(Ref ref) =>
    WatchUnreadMentionCountUseCase(ref.watch(activityRepositoryProvider));

/// The unread mentions: the badge of the tab and the count of the title.
@riverpod
Stream<int> unreadMentionCount(Ref ref) =>
    ref.watch(watchUnreadMentionCountUseCaseProvider).execute();
