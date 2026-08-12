import 'package:twake_chat/data/datasource/capabilities/server_capabilities_datasource.dart';
import 'package:twake_chat/data/network/capabilities/server_capabilities_api.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
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
