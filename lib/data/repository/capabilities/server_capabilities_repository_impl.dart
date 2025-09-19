import 'package:fluffychat/data/datasource/capabilities/server_capabilities_datasource.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/repository/capabilities/server_capabilities_repository.dart';
import 'package:matrix/matrix.dart';

class ServerCapabilitiesRepositoryImpl implements ServerCapabilitiesRepository {
  const ServerCapabilitiesRepositoryImpl();

  @override
  Future<Capabilities> getCapabilities() {
    final dataSource = getIt.get<ServerCapabilitiesDatasource>();
    return dataSource.getCapabilities();
  }
}
