import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource_impl/activity/activity_mentions_datasource.provider.dart';
import 'package:twake_chat/data/repository/activity/activity_mentions_repository_impl.dart';
import 'package:twake_chat/domain/model/activity/activity_item.dart';
import 'package:twake_chat/domain/repository/activity/activity_mentions_repository.dart';

part 'activity_mentions_repository.provider.g.dart';

@riverpod
ActivityMentionsRepository activityMentionsRepository(Ref ref) =>
    ActivityMentionsRepositoryImpl(
      ref.watch(activityMentionsDatasourceProvider),
    );

/// The mentions, read from the server each time the tab opens.
@riverpod
Future<List<ActivityItem>> activityMentions(Ref ref) =>
    ref.watch(activityMentionsRepositoryProvider).getMentions();
