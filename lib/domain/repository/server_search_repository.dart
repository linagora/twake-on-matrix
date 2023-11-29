import 'package:fluffychat/data/model/search/server_search_response.dart';
import 'package:matrix/matrix.dart';

abstract class ServerSearchRepository {
  Future<ServerSearchResponse> search({
    required Categories searchCategories,
    String? nextBatch,
  });
}
