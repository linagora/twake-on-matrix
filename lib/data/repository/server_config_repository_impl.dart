import 'package:twake_chat/data/datasource/server_config_datasource.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/model/server_config.dart';
import 'package:twake_chat/domain/repository/server_config_repository.dart';

class ServerConfigRepositoryImpl implements ServerConfigRepository {
  final ServerConfigDatasource _dataSource = getIt
      .get<ServerConfigDatasource>();

  ServerConfigRepositoryImpl();

  @override
  Future<ServerConfig> getServerConfig() async {
    return await _dataSource.getServerConfig();
  }
}
