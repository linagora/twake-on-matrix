import 'package:fluffychat/data/datasource/capabilities/server_capabilities_datasource.dart';
import 'package:fluffychat/data/network/capabilities/server_capabilities_api.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:matrix/matrix.dart';

class ServerCapabilitiesDatasourceImpl implements ServerCapabilitiesDatasource {
  const ServerCapabilitiesDatasourceImpl();

  @override
  Future<Capabilities> getCapabilities() async {
    final api = getIt.get<ServerCapabilitiesAPI>();
    final result = await api.getCapabilities();
    return result.capabilities;
  }
}
