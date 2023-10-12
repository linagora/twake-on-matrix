import 'dart:async';

import 'package:flutter/material.dart';

class OneTimeDebouncer {
  final int milliseconds;
  Timer? _timer;

  OneTimeDebouncer({required this.milliseconds});

  void run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }

    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}
