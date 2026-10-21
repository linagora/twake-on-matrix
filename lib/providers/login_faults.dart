import 'package:flutter/foundation.dart';
import 'package:matrix/matrix.dart';

/// Debug-only: makes the set-up that follows a login throw once, so the
/// rollback of a stored account can be tried by hand or in tests. Armed with
/// `--dart-define=FAULT_SETUP_ONCE=true`; `--dart-define=FAULT_SETUP_AFTER=1`
/// lets the first set-up through. In a release build [kDebugMode] is a
/// constant `false`, so a caller guarded by it leaves this class unused and it
/// is compiled out.
class LoginFaults {
  LoginFaults({
    bool failSetUpOnce = const bool.fromEnvironment('FAULT_SETUP_ONCE'),
    int succeedFirst = const int.fromEnvironment('FAULT_SETUP_AFTER'),
  }) : _failSetUpOnce = failSetUpOnce,
       _succeedFirst = succeedFirst;

  bool _failSetUpOnce;
  int _succeedFirst;

  void maybeFailSetUp(String clientName) {
    if (_shouldFail()) {
      _failSetUpOnce = false;
      Logs().w('FaultInjection: set-up of $clientName fails once');
      throw StateError('Injected fault: set-up of $clientName');
    }
  }

  /// Counts a call down only while the fault is armed.
  bool _shouldFail() {
    if (!kDebugMode || !_failSetUpOnce) return false;
    return _succeedFirst-- <= 0;
  }
}
