import 'package:matrix/matrix.dart';

/// Tells the logout handlers which logouts are not account logouts: the
/// sign-out of a login that could not be stored. It holds no timer.
///
/// A client that was signed out on purpose can still report logout states
/// afterwards, for example a soft logout from its sync loop once its token is
/// revoked. They are skipped too, until the client logs in again.
class QuietLogouts {
  /// Clients about to be signed out, whose logout was not seen yet.
  final Set<String> _announced = {};

  /// Clients whose announced logout was seen; they stay quiet until a login.
  final Set<String> _signedOut = {};

  /// Announces that [clientName] is about to be signed out on purpose. Call it
  /// before the logout.
  void announce(String clientName) {
    _signedOut.remove(clientName);
    _announced.add(clientName);
  }

  /// Drops every mark of [clientName]: its client is gone or its handlers
  /// are, so nothing will consume them.
  void forget(String clientName) {
    _announced.remove(clientName);
    _signedOut.remove(clientName);
  }

  /// True when [state] of [clientName] belongs to the quiet sign-out and the
  /// handlers must skip it. A login of the client ends the quiet period.
  bool consume(String clientName, LoginState state) {
    switch (state) {
      case LoginState.loggedIn:
        _announced.remove(clientName);
        _signedOut.remove(clientName);
        return false;
      case LoginState.loggedOut:
        if (_announced.remove(clientName)) {
          _signedOut.add(clientName);
          return true;
        }
        return _signedOut.contains(clientName);
      case LoginState.softLoggedOut:
        return _announced.contains(clientName) ||
            _signedOut.contains(clientName);
    }
  }
}
