import 'package:twake_chat/data/datasource/reactions/reactions_datasource.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/repository/reactions/reactions_repository.dart';

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
