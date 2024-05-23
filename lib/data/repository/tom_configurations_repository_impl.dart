import 'package:fluffychat/data/datasource/tom_configurations_datasource.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/tom_configurations.dart';
import 'package:fluffychat/domain/repository/tom_configurations_repository.dart';

class ToMConfigurationsRepositoryImpl implements ToMConfigurationsRepository {
  final ToMConfigurationsDatasource tomConfigurationsDatasource =
      getIt.get<ToMConfigurationsDatasource>();

  @override
  Future<ToMConfigurations> getTomConfigurations(String userId) {
    return tomConfigurationsDatasource.getTomConfigurations(userId);
  }

  @override
  Future<void> saveTomConfigurations(
    String userId,
    ToMConfigurations toMConfigurations,
  ) {
    return tomConfigurationsDatasource.saveTomConfigurations(
      userId,
      toMConfigurations,
    );
  }

  @override
  Future<void> deleteTomConfigurations(String userId) {
    return tomConfigurationsDatasource.deleteTomConfigurations(userId);
  }
}
