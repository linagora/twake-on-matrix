import 'package:fluffychat/data/datasource/server_search_datasource.dart';
import 'package:fluffychat/data/model/search/server_search_response.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/repository/server_search_repository.dart';
import 'package:matrix/matrix.dart';

class ServerSearchRepositoryImpl extends ServerSearchRepository {
  final ServerSearchDatasource _serverSearchDatasource =
      getIt.get<ServerSearchDatasource>();

  @override
  Future<ServerSearchResponse> search({
    required Categories searchCategories,
    String? nextBatch,
  }) {
    return _serverSearchDatasource.search(
      searchCategories: searchCategories,
      nextBatch: nextBatch,
    );
  }
}
