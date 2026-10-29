import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/account/entities/account_id.dart';
import 'package:twake_chat/data/account/login_host.dart';
import 'package:twake_chat/data/account/login_session.dart';

/// The client a login screen uses, and what becomes of it. It finds the
/// placeholder or the pending candidate, or makes a candidate, and hands the
/// login events and the "user left" signal to the session that owns the
/// client.
///
/// `MatrixState` attaches its [LoginHost] in `initState`, before any login
/// screen exists, and releases it when it goes away: the sessions belong to
/// that host and end with it.
class LoginSessions {
  LoginSessions([this._attached]);

  LoginHost? _attached;
  final Map<String, LoginSession> _byId = {};
  LoginSession? _pending;

  /// Sessions replaced by a new login that still have a listener or a set-up
  /// to retry. Dropping them would leak the listener and lose the set-up.
  final List<LoginSession> _replaced = [];

  LoginHost get _host =>
      _attached ?? (throw StateError('The login host is not set yet'));

  /// Serves [host] from now on, with no session of a previous host.
  void attach(LoginHost host) {
    _attached = host;
    _byId.clear();
    _replaced.clear();
    _pending = null;
  }

  /// Takes [owner] out when its state goes away, so that the next
  /// `MatrixState` on the container starts with its own host. A host that
  /// someone else has attached since stays.
  void release(LoginHost owner) {
    if (!identical(_attached, owner)) return;
    _attached = null;
    _byId.clear();
    _replaced.clear();
    _pending = null;
  }

  /// The unlogged client for a login screen: the placeholder of a logged-out
  /// boot, else the pending candidate, else a new one. Calls made while the
  /// candidate is being made share it. Cleanups that failed before are
  /// retried first.
  Future<Client> loginClient() async {
    // Read before the retry starts, so a missing host fails this call only.
    final host = _host;
    // Started here, awaited before a client is handed out. Everything up to
    // the first await runs at once, so a candidate that is being made is
    // already `_pending` when the user leaves and `discardPending` runs.
    final retry = retryFailedCleanups();
    _forgetDisposed();
    final reusable = _reusableClient();
    if (reusable != null) {
      await _settled(retry);
      // The retry may have ended the client that was read before it.
      return identical(host.reusableClient, reusable)
          ? reusable
          : loginClient();
    }
    final pending = _pending;
    if (pending != null && pending.isUsable) {
      await _settled(retry);
      return pending.isUsable ? pending.ready : loginClient();
    }
    return _newCandidate(retry);
  }

  /// The client the app already has for a login: the placeholder of a
  /// logged-out boot or the pending candidate, unless its owner cannot take a
  /// new login. A session that is still live but not usable (`cleanupFailed`,
  /// `registering`, `rollingBack`) would throw from [trackLogin]; a pending
  /// candidate that is no longer usable is the same. The caller then gets a
  /// new candidate, and the failed cleanup is retried on its own.
  ///
  /// A session that is `active` is still handed out. It is not usable, but it
  /// is not live either: the screen logs in again on that same client, and
  /// [trackLogin] replaces the session instead of throwing.
  Client? _reusableClient() {
    final reusable = _host.reusableClient;
    if (reusable == null) return null;
    final owner = _byId[reusable.clientName];
    if (owner == null) return reusable;
    final blocks =
        !owner.isUsable && (owner.isLive || identical(owner, _pending));
    return blocks ? null : reusable;
  }

  Future<Client> _newCandidate(Future<void> retry) async {
    final session = _pending = LoginSession.candidate(_host);
    // Registered as soon as the client exists, not after the retry: an event
    // of that client must find this session, not make a placeholder.
    final registered = session.ready.then<void>(
      (client) {
        _byId[client.clientName] = session;
      },
      onError: (_) {
        if (identical(_pending, session)) _pending = null;
      },
    );
    await _settled(retry);
    await registered;
    return session.ready;
  }

  /// A retry that fails is reported and does not stop the login that waits
  /// for it: the cleanups it could not finish stay recorded and run again.
  Future<void> _settled(Future<void> retry) async {
    try {
      await retry;
    } catch (error, stackTrace) {
      _host.report(error, stackTrace, 'retry of the failed cleanups');
    }
  }

  /// Runs a login of a screen for [client] so that leaving waits for it.
  ///
  /// A live session is used at once. Replacing one that is not live waits
  /// until its listener is cancelled and its failed set-ups have been tried
  /// again, so the new login does not drop either.
  Future<T> trackLogin<T>(Client client, Future<T> Function() login) {
    final existing = _byId[client.clientName];
    if (existing != null && existing.isLive) return existing.trackLogin(login);
    return _trackOnPlaceholder(client, login);
  }

  Future<T> _trackOnPlaceholder<T>(
    Client client,
    Future<T> Function() login,
  ) async {
    final existing = _byId[client.clientName];
    if (existing != null && !existing.isLive) {
      if (!_replaced.contains(existing)) _replaced.add(existing);
      await existing.relinquish();
      if (!existing.retainsWork) _replaced.remove(existing);
    }
    return _sessionOf(client).trackLogin(login);
  }

  /// The login state `loggedIn` of a client the app listens to (the boot
  /// placeholder, or an account that logs in again).
  ///
  /// A session that exists keeps the event: a candidate that is already
  /// active ignores a repeated one, and a client the app dropped gets none.
  Future<void> onLoggedIn(Client client, LoginState loginState) {
    final name = client.clientName;
    if (_host.clientByName(AccountId(name)) == null) return Future.value();
    var session = _byId[name];
    if (session == null || session.state == LoginSessionState.disposed) {
      session = _byId[name] = LoginSession.placeholder(_host, client);
    }
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
      for (final session in _replaced.toList()) session.relinquish(),
    ]);
    _replaced.removeWhere((session) => !session.retainsWork);
  }

  /// The session a screen logs in with: one that is live, else a new
  /// placeholder. Not the rule of [onLoggedIn], which also keeps an `active`
  /// session: an event is handed to the session that has the account, but a
  /// login try needs one that can still log in (`created`). Replacing an
  /// `active` session is done by [trackLogin], which cancels its listener and
  /// retries the set-ups that failed before this placeholder is created.
  LoginSession _sessionOf(Client client) {
    final existing = _byId[client.clientName];
    if (existing != null && existing.isLive) return existing;
    return _byId[client.clientName] = LoginSession.placeholder(_host, client);
  }

  /// The session of [id].
  @visibleForTesting
  LoginSession? sessionOf(String id) => _byId[id];
}
