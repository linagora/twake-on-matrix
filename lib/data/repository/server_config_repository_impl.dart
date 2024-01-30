import 'package:fluffychat/data/datasource/server_config_datasource.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/repository/server_config_repository.dart';
import 'package:matrix/matrix.dart';

class ServerConfigRepositoryImpl implements ServerConfigRepository {
  final ServerConfigDatasource _dataSource =
      getIt.get<ServerConfigDatasource>();

  ServerConfigRepositoryImpl();

  @override
  Future<ServerConfig> getServerConfig() async {
    return await _dataSource.getServerConfig();
  }
}
