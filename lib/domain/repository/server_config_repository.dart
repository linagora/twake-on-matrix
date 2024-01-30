import 'package:matrix/matrix.dart';

abstract class ServerConfigRepository {
  Future<ServerConfig> getServerConfig();
}
