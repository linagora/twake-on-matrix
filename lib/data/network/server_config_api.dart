import 'package:fluffychat/data/network/dio_client.dart';
import 'package:fluffychat/data/network/homeserver_endpoint.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/di/global/network_di.dart';
import 'package:matrix/matrix.dart';

class ServerConfigAPI {
  final DioClient _client =
      getIt.get<DioClient>(instanceName: NetworkDI.homeDioClientName);

  ServerConfigAPI();

  Future<ServerConfig> getServerConfig() async {
    final response = await _client
        .get(
          HomeserverEndpoint.configPath.generateHomeserverMediaEndpoint(),
        )
        .onError((error, stackTrace) => throw Exception(error));

    return ServerConfig.fromJson(response);
  }
}
