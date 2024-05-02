import 'package:fluffychat/data/model/search/public_room_request.dart';
import 'package:fluffychat/data/model/search/public_room_response.dart';
import 'package:fluffychat/data/network/dio_client.dart';
import 'package:fluffychat/data/network/homeserver_endpoint.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/di/global/network_di.dart';
import 'package:matrix/matrix.dart';

class PublicRoomAPI {
  final DioClient _client =
      getIt.get<DioClient>(instanceName: NetworkDI.homeDioClientName);

  PublicRoomAPI();

  Future<PublicRoomResponse> search({
    PublicRoomQueryFilter? filter,
    String? server,
    int? limit,
  }) async {
    final Map<String, dynamic> queryParameters = {};
    if (server?.isNotEmpty == true) {
      queryParameters['server'] = server;
    }
    final response = await _client
        .post(
          HomeserverEndpoint.publicRoomsPath
              .generateHomeserverServerSearchPath(),
          queryParameters: queryParameters,
          data: PublicRoomRequest(
            filter: filter,
            limit: limit,
          ),
        )
        .onError((error, stackTrace) => throw Exception(error));

    return PublicRoomResponse.fromJson(response.data);
  }
}
