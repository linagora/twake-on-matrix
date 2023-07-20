import 'package:fluffychat/data/datasource/tom_configurations_datasource.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/tom_configurations.dart';
import 'package:fluffychat/domain/repository/tom_configurations_repository.dart';

class ToMConfigurationsRepositoryImpl implements ToMConfigurationsRepository {
  final ToMConfigurationsDatasource tomConfigurationsDatasource =
      getIt.get<ToMConfigurationsDatasource>();

  @override
  Future<ToMConfigurations> getTomConfigurations(String clientName) {
    return tomConfigurationsDatasource.getTomConfigurations(clientName);
  }

  @override
  Future<void> saveTomConfigurations(
      String clientName, ToMConfigurations toMConfigurations) {
    return tomConfigurationsDatasource.saveTomConfigurations(
        clientName, toMConfigurations);
  }
}
