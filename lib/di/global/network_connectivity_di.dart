import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluffychat/di/base_di.dart';
import 'package:fluffychat/utils/network_connection_service.dart';
import 'package:get_it/get_it.dart';

class NetworkConnectivityDI extends BaseDI {
  @override
  void setUp(GetIt get) {
    _bindDioForNetworkConnectionService(get);
  }

  void _bindDioForNetworkConnectionService(GetIt get) {
    get.registerLazySingleton<Connectivity>(
      () => Connectivity(),
    );
    get.registerLazySingleton<NetworkConnectionService>(
      () => NetworkConnectionService(get.get<Connectivity>()),
    );
  }
}
