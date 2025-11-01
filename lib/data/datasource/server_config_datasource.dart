import 'package:fluffychat/domain/model/server_config.dart';

abstract class ServerConfigDatasource {
  Future<ServerConfig> getServerConfig();
}
