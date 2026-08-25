import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/utils/famedlysdk_store.dart';
import 'package:matrix/matrix.dart';

class ReactionsCacheManager {
  static const keyRecentReactions = 'RECENT_REACTIONS';

  final Store pres = getIt.get<Store>();

  Future<void> storeRecentReactions(List<String> recentReactions) async {
    await pres.setItems(keyRecentReactions, recentReactions);
  }

  Future<List<String>?> getRecentReactions() async {
    return await pres.getItems(keyRecentReactions);
  }

  Future<void> removeRecentReactions() async {
    return Future.sync(() async {
      await pres.deleteItem(keyRecentReactions);
    }).catchError((error) {
      Logs().e('ReactionCacheManager::removeRecentReactions(): error: $error');
      return null;
    });
  }
}
