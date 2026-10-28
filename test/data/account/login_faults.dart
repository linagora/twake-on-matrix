import 'one_shot_fault.dart';

/// Makes the set-up that follows a login throw once, so the rollback of a
/// stored account can be tried. It is disarmed unless armed through the
/// constructor, and only tests use it. `succeedFirst` lets that many set-ups
/// through before the failure.
class LoginFaults {
  LoginFaults({bool failSetUpOnce = false, int succeedFirst = 0})
    : _setUp = OneShotFault(armed: failSetUpOnce, succeedFirst: succeedFirst);

  final OneShotFault _setUp;

  void maybeFailSetUp(String clientName) =>
      _setUp.maybeThrow('set-up of $clientName');
}
