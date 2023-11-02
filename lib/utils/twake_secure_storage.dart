import 'dart:async';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:matrix/matrix.dart';

class TwakeSecureStorage {
  const TwakeSecureStorage();

  final _secureStorage = const FlutterSecureStorage();

  Future<String?> read({required String key}) async {
    if (Platform.isIOS) {
      try {
        final isAvailable =
            await _secureStorage.isCupertinoProtectedDataAvailable();
        if (isAvailable) {
          return _secureStorage.read(key: key);
        }
        Logs().wtf('Cupertino protected data is not available');
        final completer = Completer<String?>();
        late StreamSubscription<bool> subsciption;
        subsciption = _secureStorage.onCupertinoProtectedDataAvailabilityChanged
            .listen((isAvailable) {
          Logs()
              .wtf('onCupertinoProtectedDataAvailabilityChanged: $isAvailable');
          if (isAvailable) {
            completer.complete(_secureStorage.read(key: key));
            subsciption.cancel();
          }
        });
        Logs().wtf('onCupertinoProtectedDataAvailabilityChanged: done');
        return completer.future;
      } catch (e) {
        Logs().wtf('Failed to read from secure storage: $e');
        return null;
      }
    }
    return _secureStorage.read(key: key);
  }

  Future<void> write({required String key, required String? value}) async {
    return _secureStorage.write(key: key, value: value);
  }

  Future<void> delete({required String key}) async {
    return _secureStorage.delete(key: key);
  }
}
