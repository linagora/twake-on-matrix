import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/network_connection_service.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix_api_lite/utils/logs.dart';

mixin ConnectivityMixin<T extends StatefulWidget> on State<T> {
  StreamSubscription? _connectivitySubscription;

  Future<void> onConnect();

  @override
  void initState() {
    super.initState();
    _connectivitySubscription = getIt
        .get<NetworkConnectionService>()
        .getStreamInstance()
        .listen((event) {
          if (event != ConnectivityResult.none) {
            onConnect().onError((error, stackTrace) {
              Logs().e('ConnectivityMixin: onConnect error', error, stackTrace);
            });
          }
        });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
