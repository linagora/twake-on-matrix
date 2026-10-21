import 'dart:async';

import 'package:matrix/matrix.dart';
import 'package:twake_chat/providers/login_host.dart';
import 'package:twake_chat/providers/login_session.dart';

/// The client a login screen uses, and what becomes of it. It finds the
/// placeholder or the pending candidate, or makes a candidate, and hands the
/// login events and the "user left" signal to the session that owns the
/// client.
class LoginSessions {
  LoginSessions(this._host);

  final LoginHost _host;
  final Map<String, LoginSession> _byId = {};
  LoginSession? _pending;

  /// The unlogged client for a login screen: the placeholder of a logged-out
  /// boot, else the pending candidate, else a new one. Calls made while the
  /// candidate is being made share it. Cleanups that failed before are
  /// retried first.
  Future<Client> loginClient() async {
    // Started here, awaited before a client is handed out. Everything up to
    // the first await runs at once, so a candidate that is being made is
    // already `_pending` when the user leaves and `discardPending` runs.
    final retry = retryFailedCleanups();
    _forgetDisposed();
    final reusable = _host.reusableClient;
    if (reusable != null) {
      await retry;
      // The retry may have ended the client that was read before it.
      return identical(_host.reusableClient, reusable)
          ? reusable
          : loginClient();
    }
    final pending = _pending;
    if (pending != null && pending.isUsable) {
      await retry;
      return pending.isUsable ? pending.ready : loginClient();
    }
    final session = _pending = LoginSession.candidate(_host);
    await retry;
    try {
      final client = await session.ready;
      _byId[client.clientName] = session;
      return client;
    } catch (_) {
      if (identical(_pending, session)) _pending = null;
      rethrow;
    }
  }

  /// Runs a login of a screen for [client] so that leaving waits for it.
  Future<T> trackLogin<T>(Client client, Future<T> Function() login) =>
      _sessionOf(client).trackLogin(login);

  /// The login state `loggedIn` of a client the app listens to (the boot
  /// placeholder, or an account that logs in again).
  ///
  /// A session that exists keeps the event: a candidate that is already
  /// active ignores a repeated one, and a client the app dropped gets none.
  Future<void> firstLoggedIn(Client client, LoginState loginState) {
    final name = client.clientName;
    if (_host.clientByName(name) == null) return Future.value();
    final existing = _byId[name];
    final session =
        existing != null && existing.state != LoginSessionState.disposed
        ? existing
        : _byId[name] = LoginSession.placeholder(_host, client);
    return session.onLoggedIn(loginState);
  }

  /// Drops the sessions that ended, so attempts do not pile them up. A
  /// session that keeps its client is never disposed.
  void _forgetDisposed() => _byId.removeWhere(
    (_, session) => session.state == LoginSessionState.disposed,
  );

  /// The user left the add-account flow: the pending candidate is thrown away
  /// unless it became an account. Waits for what is going on, and shares a
  /// call made at the same time.
  Future<void> discardPending() async {
    final pending = _pending;
    if (pending == null) return;
    await pending.dispose();
    if (!pending.isLive && identical(_pending, pending)) _pending = null;
  }

  /// Runs again the removals of logged-out accounts that failed, then the
  /// cleanup steps that failed, for every session. The removals go first: a
  /// session whose step is handed to them finds it done, not still running.
  Future<void> retryFailedCleanups() async {
    await _host.retryPendingRemovals();
    await Future.wait([
      for (final session in _byId.values.toList())
        if (session.needsRetry) session.retryCleanup(),
    ]);
  }

  LoginSession _sessionOf(Client client) {
    final existing = _byId[client.clientName];
    if (existing != null && existing.isLive) return existing;
    return _byId[client.clientName] = LoginSession.placeholder(_host, client);
  }

  /// The session of [id], for tests and diagnostics.
  LoginSession? sessionOf(String id) => _byId[id];
}
