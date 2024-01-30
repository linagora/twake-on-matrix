import 'package:matrix/matrix.dart';

abstract class ServerConfigDatasource {
  Future<ServerConfig> getServerConfig();
}
