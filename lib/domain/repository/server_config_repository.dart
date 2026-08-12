import 'package:twake_chat/domain/model/server_config.dart';

abstract class ServerConfigRepository {
  Future<ServerConfig> getServerConfig();
}
