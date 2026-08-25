import 'package:twake_chat/data/datasource/tom_configurations_datasource.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/model/tom_configurations.dart';
import 'package:twake_chat/domain/repository/tom_configurations_repository.dart';

class ToMConfigurationsRepositoryImpl implements ToMConfigurationsRepository {
  final ToMConfigurationsDatasource tomConfigurationsDatasource = getIt
      .get<ToMConfigurationsDatasource>();

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
