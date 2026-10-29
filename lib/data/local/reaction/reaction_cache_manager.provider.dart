import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/local/reaction/reaction_cache_manager.dart';
import 'package:twake_chat/utils/famedlysdk_store.provider.dart';

part 'reaction_cache_manager.provider.g.dart';

@riverpod
ReactionsCacheManager reactionsCacheManager(Ref ref) =>
    ReactionsCacheManager(ref.watch(storeProvider));
