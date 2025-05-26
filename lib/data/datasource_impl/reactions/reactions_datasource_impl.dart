import 'package:fluffychat/data/datasource/reactions/reactions_datasource.dart';
import 'package:fluffychat/data/local/reaction/reaction_cache_manager.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';

class ReactionsDatasourceImpl implements ReactionsDatasource {
  final reactionCacheManager = getIt.get<ReactionsCacheManager>();

  @override
  Future<List<String>> getRecentReactions() {
    return reactionCacheManager.getRecentReactions().then((reactions) {
      if (reactions == null || reactions.isEmpty) {
        return [];
      }
      return reactions;
    });
  }

  @override
  Future<void> removeRecentReactions() {
    return reactionCacheManager.removeRecentReactions();
  }

  @override
  Future<void> storeRecentReactions(List<String> recentReactions) {
    return reactionCacheManager.storeRecentReactions(recentReactions);
  }
}
