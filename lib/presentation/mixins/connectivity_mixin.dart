import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/network_connection_service.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix_api_lite/utils/logs.dart';

mixin ConnectivityMixin<T extends StatefulWidget> on State<T> {
  StreamSubscription? _connectivitySubscription;

  Future<void> onConnect();

  late final Debouncer<bool?> _debouncer;

  @override
  void initState() {
    super.initState();
    _debouncer = Debouncer<bool?>(
      const Duration(seconds: 5),
      initialValue: null,
      onChanged: (value) async {
        if (value != true) return;

        await onConnect().onError((error, stackTrace) {
          Logs().e('ConnectivityMixin: onConnect error', error, stackTrace);
        });
      },
    );
    _connectivitySubscription = getIt
        .get<NetworkConnectionService>()
        .getStreamInstance()
        .listen((event) {
          _debouncer.value = event != ConnectivityResult.none;
        });
  }

  @override
  void dispose() {
    _debouncer.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
