import 'package:fluffychat/data/datasource/server_config_datasource.dart';
import 'package:fluffychat/data/network/server_config_api.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:matrix/matrix.dart';

class ServerConfigDatasourceImpl implements ServerConfigDatasource {
  final ServerConfigAPI _serverConfigAPI = getIt.get<ServerConfigAPI>();

  ServerConfigDatasourceImpl();

  @override
  Future<ServerConfig> getServerConfig() async {
    return await _serverConfigAPI.getServerConfig();
  }
}
