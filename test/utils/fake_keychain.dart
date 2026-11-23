import 'dart:collection';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The values behind the test secure storage, with switches for the keychain
/// failures seen on desktop: a read that fails, a write that is silently
/// lost or altered, a delete that fails.
///
/// [install] hands it to `FlutterSecureStorage.setMockInitialValues`, whose
/// test platform reads, writes and removes through this map.
class FakeKeychain extends MapBase<String, String> {
  final _values = <String, String>{};

  bool failReads = false;
  bool loseWrites = false;
  bool failDeletes = false;
  String Function(String value)? alterWrites;

  void install() => FlutterSecureStorage.setMockInitialValues(this);

  static PlatformException _error(String op) => PlatformException(
    code: 'errSecInteractionNotAllowed',
    message: 'keychain $op failed',
  );

  @override
  String? operator [](Object? key) {
    if (failReads) throw _error('read');
    return _values[key];
  }

  @override
  void operator []=(String key, String value) {
    if (loseWrites) return;
    _values[key] = alterWrites?.call(value) ?? value;
  }

  @override
  String? remove(Object? key) {
    if (failDeletes) throw _error('delete');
    return _values.remove(key);
  }

  @override
  void clear() => _values.clear();

  @override
  Iterable<String> get keys => _values.keys;

  /// The stored value, bypassing the failure switches.
  String? stored(String key) => _values[key];
}
