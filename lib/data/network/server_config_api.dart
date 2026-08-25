import 'package:twake_chat/data/network/dio_client.dart';
import 'package:twake_chat/data/network/homeserver_endpoint.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/di/global/network_di.dart';
import 'package:twake_chat/domain/model/server_config.dart';

class ServerConfigAPI {
  final DioClient _client = getIt.get<DioClient>(
    instanceName: NetworkDI.homeDioClientName,
  );

  ServerConfigAPI();

  Future<ServerConfig> getServerConfig() async {
    final response = await _client
        .get(HomeserverEndpoint.configPath.generateHomeserverMediaEndpoint())
        .onError((error, stackTrace) => throw Exception(error));

    return ServerConfig.fromJson(response);
  }
}
