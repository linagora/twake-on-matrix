import 'package:flutter/foundation.dart';

class ValueNotifierCustom<T> extends ValueNotifier<T> {
  bool _isDisposed = false;

  ValueNotifierCustom(super.value);

  bool get isDisposed => _isDisposed;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
