import 'package:twake_chat/data/datasource/server_search_datasource.dart';
import 'package:twake_chat/data/network/search/server_search_api.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/model/search/server_search_response.dart';

class ServerSearchDatasourceImpl extends ServerSearchDatasource {
  final ServerSearchAPI _serverSearchAPI = getIt.get<ServerSearchAPI>();

  @override
  Future<ServerSearchResponse> search({
    required Categories searchCategories,
    String? nextBatch,
  }) {
    return _serverSearchAPI.search(
      searchCategories: searchCategories,
      nextBatch: nextBatch,
    );
  }
}
