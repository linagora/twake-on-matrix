import 'package:fluffychat/domain/model/tom_configurations.dart';

abstract class ToMConfigurationsDatasource {
  Future<ToMConfigurations> getTomConfigurations(String clientName);

  Future<void> saveTomConfigurations(
    String clientName,
    ToMConfigurations toMConfigurations,
  );
}
