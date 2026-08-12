import 'package:twake_chat/data/datasource/capabilities/server_capabilities_datasource.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/repository/capabilities/server_capabilities_repository.dart';
import 'package:matrix/matrix.dart';

class ServerCapabilitiesRepositoryImpl implements ServerCapabilitiesRepository {
  const ServerCapabilitiesRepositoryImpl();

  @override
  Future<Capabilities> getCapabilities() {
    final dataSource = getIt.get<ServerCapabilitiesDatasource>();
    return dataSource.getCapabilities();
  }
}
