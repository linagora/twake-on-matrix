import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource/reactions/reactions_datasource.dart';
import 'package:twake_chat/data/datasource_impl/reactions/reactions_datasource_impl.dart';
import 'package:twake_chat/data/local/reaction/reaction_cache_manager.provider.dart';

part 'reactions_datasource.provider.g.dart';

@riverpod
ReactionsDatasource reactionsDatasource(Ref ref) =>
    ReactionsDatasourceImpl(ref.watch(reactionsCacheManagerProvider));
