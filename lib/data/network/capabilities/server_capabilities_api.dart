import 'package:fluffychat/data/model/capabilities/server_capabilities_response.dart';
import 'package:fluffychat/data/network/dio_client.dart';
import 'package:fluffychat/data/network/homeserver_endpoint.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/di/global/network_di.dart';

class ServerCapabilitiesAPI {
  const ServerCapabilitiesAPI();

  Future<ServerCapabilitiesResponse> getCapabilities() async {
    final client = getIt.get<DioClient>(
      instanceName: NetworkDI.homeDioClientName,
    );

    final response = await client.get(
      HomeserverEndpoint.capabilitiesPath.generateHomeserverCapabilitiesPath(),
    );
    return ServerCapabilitiesResponse.fromJson(response);
  }
}
