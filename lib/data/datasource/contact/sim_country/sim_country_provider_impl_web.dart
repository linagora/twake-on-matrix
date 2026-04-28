import 'package:fluffychat/data/datasource/contact/sim_country/sim_country_provider.dart';

/// Web: no SIM / no VM [Platform]; country hint is not available for phonebook sync.
class SimCountryProviderImpl implements SimCountryProvider {
  @override
  Future<String?> getCountryCode() async => null;
}
