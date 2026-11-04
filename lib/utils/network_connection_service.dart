import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:matrix/matrix.dart';

class NetworkConnectionService {
  final Connectivity connectivity;
  late StreamController<ConnectivityResult> networkStreamController;
  late StreamSubscription<List<ConnectivityResult>> networkStreamSubscription;

  NetworkConnectionService(this.connectivity);

  void onInit() {
    _setupNetworkStream();
    _listenNetworkConnectionChanged();
  }

  void onDispose() {
    networkStreamController.close();
    networkStreamSubscription.cancel();
  }

  void _setupNetworkStream() {
    networkStreamController = StreamController<ConnectivityResult>.broadcast();
    getCurrentNetworkConnectionState();
  }

  void _listenNetworkConnectionChanged() {
    networkStreamSubscription = connectivity.onConnectivityChanged.listen(
      (result) {
        Logs().d(
          'NetworkConnectionService::_listenNetworkConnectionChanged():onConnectivityChanged: $result',
        );
        _setNetworkConnectivityState(result.primary);
      },
      onError: (error, stackTrace) {
        Logs().e(
          'NetworkConnectionService::_listenNetworkConnectionChanged():error: $error',
        );
        Logs().e(
          'NetworkConnectionService::_listenNetworkConnectionChanged():stackTrace: $stackTrace',
        );
      },
    );
  }

  void _setNetworkConnectivityState(ConnectivityResult newConnectivityResult) {
    Logs().d(
      'NetworkConnectionService::_setNetworkConnectivityState():newConnectivityResult: $newConnectivityResult',
    );
    networkStreamController.add(newConnectivityResult);
  }

  Future<bool> isNetworkConnectionAvailable() async {
    return (await connectivity.checkConnectivity()).primary !=
        ConnectivityResult.none;
  }

  void getCurrentNetworkConnectionState() async {
    final currentConnectionResult = await connectivity.checkConnectivity();
    Logs().d(
      'NetworkConnectionService::onReady():_getCurrentNetworkConnectionState: $currentConnectionResult',
    );
    _setNetworkConnectivityState(currentConnectionResult.primary);
  }

  Stream<ConnectivityResult> getStreamInstance() {
    Logs().d('NetworkConnectionService::getStreamInstance()');

    getCurrentNetworkConnectionState();
    return networkStreamController.stream;
  }
}

extension ConnectivityResultsExtension on List<ConnectivityResult> {
  ConnectivityResult get primary => firstOrNull ?? ConnectivityResult.none;
}
