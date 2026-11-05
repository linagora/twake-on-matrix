import 'package:matrix/matrix.dart';

/// The push state of the app (keychain sync, pushers, web push) that a pusher
/// deletion needs. `MatrixState` sets it after its first build and clears it
/// when it is disposed.
abstract interface class PushTeardown {
  /// Deletes the push registration of [target]; throws when it fails.
  Future<void> removePush(Client target);

  /// False while a mobile device has no push token yet.
  bool get isPushReady;

  /// Makes a failure of [what] visible.
  void report(Object error, StackTrace stackTrace, String what);
}
