import 'package:twake_chat/domain/model/server_config.dart';

abstract class ServerConfigDatasource {
  Future<ServerConfig> getServerConfig();
}
