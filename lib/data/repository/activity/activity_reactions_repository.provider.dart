import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource_impl/activity/activity_reactions_datasource.provider.dart';
import 'package:twake_chat/data/repository/activity/activity_reactions_repository_impl.dart';
import 'package:twake_chat/domain/model/activity/activity_item.dart';
import 'package:twake_chat/domain/repository/activity/activity_reactions_repository.dart';

part 'activity_reactions_repository.provider.g.dart';

@riverpod
ActivityReactionsRepository activityReactionsRepository(Ref ref) =>
    ActivityReactionsRepositoryImpl(
      ref.watch(activityReactionsDatasourceProvider),
    );

/// The reactions of the others to the messages of the user.
@riverpod
Stream<List<ActivityItem>> activityReactions(Ref ref) =>
    ref.watch(activityReactionsRepositoryProvider).watchReactions();
