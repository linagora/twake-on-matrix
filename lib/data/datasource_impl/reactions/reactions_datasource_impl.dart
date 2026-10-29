import 'package:twake_chat/data/datasource/reactions/reactions_datasource.dart';
import 'package:twake_chat/data/local/reaction/reaction_cache_manager.dart';

class ReactionsDatasourceImpl implements ReactionsDatasource {
  const ReactionsDatasourceImpl(this.reactionCacheManager);

  final ReactionsCacheManager reactionCacheManager;

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
