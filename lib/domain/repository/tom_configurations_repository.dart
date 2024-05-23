import 'package:fluffychat/domain/model/tom_configurations.dart';

abstract class ToMConfigurationsRepository {
  Future<ToMConfigurations> getTomConfigurations(String userId);

  Future<void> saveTomConfigurations(
    String userId,
    ToMConfigurations toMConfigurations,
  );

  Future<void> deleteTomConfigurations(String userId);
}
