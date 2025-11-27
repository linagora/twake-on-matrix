import 'package:fluffychat/domain/model/server_config.dart';

abstract class ServerConfigRepository {
  Future<ServerConfig> getServerConfig();
}
