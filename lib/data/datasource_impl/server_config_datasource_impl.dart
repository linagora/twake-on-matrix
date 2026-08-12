import 'package:twake_chat/data/datasource/server_config_datasource.dart';
import 'package:twake_chat/data/network/server_config_api.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/model/server_config.dart';

class ServerConfigDatasourceImpl implements ServerConfigDatasource {
  final ServerConfigAPI _serverConfigAPI = getIt.get<ServerConfigAPI>();

  ServerConfigDatasourceImpl();

  @override
  Future<ServerConfig> getServerConfig() async {
    return await _serverConfigAPI.getServerConfig();
  }
}
