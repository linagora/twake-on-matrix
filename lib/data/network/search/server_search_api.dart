import 'package:fluffychat/data/model/search/server_search_request.dart';
import 'package:fluffychat/data/model/search/server_search_response.dart';
import 'package:fluffychat/data/network/dio_client.dart';
import 'package:fluffychat/data/network/homeserver_endpoint.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/di/global/network_di.dart';
import 'package:matrix/matrix.dart';

class ServerSearchAPI {
  final DioClient _client =
      getIt.get<DioClient>(instanceName: NetworkDI.homeDioClientName);

  ServerSearchAPI();

  Future<ServerSearchResponse> search({
    required Categories searchCategories,
    String? nextBatch,
  }) async {
    final Map<String, dynamic> queryParameters = {};
    if (nextBatch?.isNotEmpty == true) {
      queryParameters['next_batch'] = nextBatch;
    }
    final response = await _client
        .post(
          HomeserverEndpoint.searchPath.generateHomeserverServerSearchPath(),
          queryParameters: queryParameters,
          data: ServerSearchRequest(searchCategories: searchCategories),
        )
        .onError((error, stackTrace) => throw Exception(error));
    return ServerSearchResponse.fromJson(response.data);
  }
}
