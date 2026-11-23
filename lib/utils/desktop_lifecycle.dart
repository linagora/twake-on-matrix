import 'package:flutter/services.dart';
import 'package:matrix/matrix.dart';

/// On macOS the app stays alive in the Dock when its last window is closed,
/// as long as an account is signed in (sync and notifications continue).
bool shouldKeepRunningAfterLastWindowClosed({
  required bool isMacOS,
  required bool isLoggedIn,
}) => isMacOS && isLoggedIn;

abstract class DesktopLifecyclePort {
  Future<void> setKeepRunningWhenWindowClosed(bool keepRunning);
}

/// [DesktopLifecyclePort] on the `app.twake/lifecycle` channel (AppDelegate).
class MethodChannelDesktopLifecyclePort implements DesktopLifecyclePort {
  static const _channel = MethodChannel('app.twake/lifecycle');

  @override
  Future<void> setKeepRunningWhenWindowClosed(bool keepRunning) =>
      _channel.invokeMethod('setKeepRunningWhenWindowClosed', keepRunning);
}

class DesktopLifecycle {
  DesktopLifecycle(this._port, {required this.isMacOS});

  final DesktopLifecyclePort _port;
  final bool isMacOS;
  bool? _last;

  /// Never throws.
  Future<void> onLoginStateChanged({required bool isLoggedIn}) async {
    final keep = shouldKeepRunningAfterLastWindowClosed(
      isMacOS: isMacOS,
      isLoggedIn: isLoggedIn,
    );
    if (!isMacOS || keep == _last) return;
    try {
      await _port.setKeepRunningWhenWindowClosed(keep);
      _last = keep;
    } catch (e, s) {
      Logs().w('[Lifecycle] native call failed', e, s);
    }
  }
}
