import 'package:fluffychat/data/datasource/reactions/reactions_datasource.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/repository/reactions/reactions_repository.dart';

class ReactionsRepositoryImpl implements ReactionsRepository {
  final ReactionsDatasource dataSource = getIt.get<ReactionsDatasource>();

  @override
  Future<List<String>> getRecentReactions() {
    return dataSource.getRecentReactions();
  }

  @override
  Future<void> removeRecentReactions() {
    return dataSource.removeRecentReactions();
  }

  @override
  Future<void> storeRecentReactions(List<String> recentReactions) {
    return dataSource.storeRecentReactions(recentReactions);
  }
}
