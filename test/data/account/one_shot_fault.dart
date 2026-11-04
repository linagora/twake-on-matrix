import 'package:matrix/matrix.dart';

/// A failure that happens once, to try the failure paths of a login. It is
/// disarmed unless armed through the constructor; [succeedFirst] lets that
/// many calls through before the failure.
class OneShotFault {
  OneShotFault({bool armed = false, int succeedFirst = 0})
    : _armed = armed,
      _succeedFirst = succeedFirst;

  bool _armed;
  int _succeedFirst;

  /// Throws a [StateError] naming [what] when the failure is due, and only
  /// then: the calls before it, and the ones after it, go through. Counts a
  /// call down only while the fault is armed.
  void maybeThrow(String what) {
    if (!_armed || _succeedFirst-- > 0) return;
    _armed = false;
    Logs().w('FaultInjection: $what fails once');
    throw StateError('Injected fault: $what');
  }
}
