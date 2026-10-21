import 'dart:async';

import 'package:matrix/matrix.dart';
import 'package:twake_chat/presentation/model/client_login_state_event.dart';
import 'package:twake_chat/providers/login_host.dart';

/// Where a login session is. The moves between states are the only ones the
/// code makes; any other move throws.
///
///     creating -> created -> loggingIn -> registering -> active
///                    ^            |             |
///                    |            v             v
///                    +--------- (failed login)  rollingBack -> disposed
///                                                    |
///                                                    +------> cleanupFailed
///
/// A session that keeps its client (the placeholder of a first login) goes back
/// to `created` after a rollback instead of `disposed`, ready for the next try.
enum LoginSessionState {
  creating,
  created,
  loggingIn,
  registering,
  active,
  rollingBack,
  disposed,
  cleanupFailed,
}

/// A step of the rollback, in the order they run. A step that fails is
/// reported and retried until it works, and the steps after it wait: the
/// account is not dropped while a handler of it is alive, and the shared state
/// is not put back before the account is gone.
///
/// Two steps never block, because the app works locally first: [removePush]
/// and [signOut] report a failure and the run goes on (the server session of
/// the account expires on its own).
enum _Cleanup {
  removePush,
  cancelSubscriptions,
  signOut,
  removeAccount,
  discardCandidate,
  restoreEffects,
  cancelListener,
  logoutLast,
}

/// A set-up that follows the login and does not decide it: when it fails the
/// account stays, the failure is reported, and the set-up is tried again.
enum _SetUp { tom, federation, recoveryKey, push }

/// The one owner of a client that is logging in: the placeholder of a first
/// login, or a candidate made for "add another account".
///
/// Every operation (create, register, set up, roll back, dispose) goes through
/// one queue and is awaited, so none of them runs against a state another one
/// is about to change. The login itself is a network call made by a screen; it
/// is tracked with [trackLogin] and awaited before the session is disposed.
class LoginSession {
  /// The session of a client that already exists. It does not listen for the
  /// login itself: the app's listener for that client hands the event to
  /// [onLoggedIn].
  LoginSession.placeholder(this._host, Client client)
    : _client = client,
      keepsClient = true,
      _state = LoginSessionState.created {
    ready = Future.value(client);
  }

  /// Creates the candidate in the background; [ready] is its client.
  LoginSession.candidate(this._host)
    : keepsClient = false,
      _state = LoginSessionState.creating {
    ready = _enqueue(_create);
  }

  final LoginHost _host;
  final bool keepsClient;

  Client? _client;
  LoginSessionState _state;
  Future<void> _tail = Future<void>.value();
  Future<void> _login = Future<void>.value();
  StreamSubscription<LoginState>? _loggedInSubscription;
  bool _accountAdded = false;

  /// True once the shared state (ToM, authorization, home server) was set for
  /// this candidate, before the account is active: the rollback puts the
  /// active account's state back.
  bool _effectsTouched = false;
  Object? _cleanupError;
  final Set<_Cleanup> _failedCleanups = {};
  final Set<_SetUp> _failedSetUps = {};

  /// The client of the session, once it exists.
  late final Future<Client> ready;

  LoginSessionState get state => _state;
  Client get client =>
      _client ?? (throw StateError('The candidate is not created yet'));
  String get id => client.clientName;

  /// True while the session can still log in.
  bool get isLive =>
      _state == LoginSessionState.creating ||
      _state == LoginSessionState.created ||
      _state == LoginSessionState.loggingIn ||
      _state == LoginSessionState.registering ||
      _state == LoginSessionState.rollingBack ||
      _state == LoginSessionState.cleanupFailed;

  /// True when a screen can use the client for a login try.
  bool get isUsable =>
      _state == LoginSessionState.creating ||
      _state == LoginSessionState.created ||
      _state == LoginSessionState.loggingIn;

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final run = _tail.then((_) => operation());
    _tail = run.then<void>((_) {}, onError: (Object _) {});
    return run;
  }

  void _move(LoginSessionState next, Set<LoginSessionState> allowedFrom) {
    if (!allowedFrom.contains(_state)) {
      throw StateError('A login session cannot go from $_state to $next');
    }
    _state = next;
  }

  Future<Client> _create() async {
    try {
      _client = await _host.createCandidate();
    } catch (_) {
      _move(LoginSessionState.disposed, {LoginSessionState.creating});
      rethrow;
    }
    _move(LoginSessionState.created, {LoginSessionState.creating});
    _host.setPendingCandidate(id);
    _listen();
    return client;
  }

  void _listen() {
    _loggedInSubscription = _host.listenLoginState(client, (state) {
      if (state == LoginState.loggedIn) unawaited(onLoggedIn(state));
    });
  }

  /// Runs [login] (a call of the login screen) and remembers it while it
  /// goes on. A login that fails leaves the session ready for another try.
  Future<T> trackLogin<T>(Future<T> Function() login) {
    if (_state == LoginSessionState.created) {
      _state = LoginSessionState.loggingIn;
    } else if (_state != LoginSessionState.loggingIn) {
      throw StateError('Cannot log in while the session is $_state');
    }
    final run = login();
    final settled = run.then<void>(
      (_) {},
      onError: (Object _) {
        if (_state == LoginSessionState.loggingIn) {
          _state = LoginSessionState.created;
        }
      },
    );
    // Logins started together are all awaited before the session is disposed.
    _login = Future.wait([_login, settled]).then<void>((_) {});
    return run;
  }

  /// The server accepted the login: store the account and set it up. A failure
  /// at any step rolls the login back. Never throws.
  Future<void> onLoggedIn(LoginState loginState) => _enqueue(() async {
    if (_state == LoginSessionState.active && keepsClient) {
      _state = LoginSessionState.created; // a new login of the same client
    }
    if (_state != LoginSessionState.created &&
        _state != LoginSessionState.loggingIn) {
      return; // a repeated event, or a session that is already ending
    }
    _state = LoginSessionState.registering;
    _failedSetUps.clear();
    try {
      if (keepsClient) {
        await _registerFirstAccount();
      } else {
        await _registerAdditionalAccount();
      }
    } catch (error, stackTrace) {
      await _rollBack(error, stackTrace);
      return;
    }
    _state = LoginSessionState.active;
    _host.emit(
      ClientLoginStateEvent(
        client: _host.activeClient,
        loginState: loginState,
        multipleAccountLoginType: keepsClient
            ? MultipleAccountLoginType.firstLoggedIn
            : MultipleAccountLoginType.otherAccountLoggedIn,
      ),
    );
    if (!keepsClient) {
      _release();
      await _cancelListenerReported();
    }
  });

  /// Only the storing of the account, its registration and the start of its
  /// session decide a login; everything else is a [_SetUp] or a best-effort
  /// step, and the account stays when it fails.
  Future<void> _registerFirstAccount() async {
    _host.markFirstSyncDone();
    await _host.addAccount(id);
    _accountAdded = true;
    _effectsTouched = true;
    await _setUp(_SetUp.tom);
    await _setUp(_SetUp.federation);
    await _host.activateCurrent();
    await _bestEffort('contact sync', () => _host.reSyncContacts());
  }

  Future<void> _registerAdditionalAccount() async {
    await _host.addAccount(id);
    _accountAdded = true;
    await _host.registerSubscriptions(id);
    final active = _host.clientByName(id);
    if (active == null) throw StateError('No client named $id');
    _host.markFirstSyncDone();
    _effectsTouched = true;
    await _setUp(_SetUp.tom);
    await _setUp(_SetUp.federation);
    await _setUp(_SetUp.recoveryKey);
    if (!await _host.switchTo(active)) {
      throw StateError('Cannot switch to $id');
    }
    await _setUp(_SetUp.push);
    await _bestEffort('contact sync', _host.cancelContactSync);
    await _bestEffort('contact sync', () => _host.reSyncContacts());
  }

  /// Runs a set-up of the login; a failure is reported and the set-up waits
  /// for [retryCleanup].
  Future<void> _setUp(_SetUp setUp) async {
    try {
      await _runSetUp(setUp);
      _failedSetUps.remove(setUp);
    } catch (e, s) {
      _failedSetUps.add(setUp);
      _host.report(e, s, 'set-up $setUp of $id failed');
    }
  }

  Future<void> _runSetUp(_SetUp setUp) {
    final target = _host.clientByName(id) ?? client;
    return switch (setUp) {
      _SetUp.tom => _host.setUpToM(target),
      _SetUp.federation => _host.setUpFederation(target),
      _SetUp.recoveryKey => _host.syncRecoveryKey(target),
      _SetUp.push => _host.setUpAdditionalPush(target),
    };
  }

  Future<void> _bestEffort(String what, FutureOr<void> Function() step) async {
    try {
      await step();
    } catch (e, s) {
      _host.report(e, s, '$what of $id failed');
    }
  }

  /// Undoes the login. The account and the storage are only reported gone
  /// when they are: a step that fails leaves the session in `cleanupFailed`,
  /// is reported, and runs again on [retryCleanup]. `loginFailed` is sent only
  /// when nothing is left behind.
  Future<void> _rollBack(Object error, StackTrace stackTrace) async {
    _move(LoginSessionState.rollingBack, {
      LoginSessionState.registering,
      LoginSessionState.created,
      LoginSessionState.loggingIn,
    });
    _host.report(error, stackTrace, 'login of $id failed');
    _failedCleanups.addAll(_steps());
    await _cleanUp();
    if (_failedCleanups.isEmpty) {
      _finishRollback();
      _host.emit(_failure(MultipleAccountLoginType.loginFailed, error));
    } else {
      _state = LoginSessionState.cleanupFailed;
      _host.emit(
        _failure(
          MultipleAccountLoginType.cleanupFailed,
          _cleanupError ?? error,
        ),
      );
    }
  }

  ClientLoginStateEvent _failure(MultipleAccountLoginType type, Object error) =>
      ClientLoginStateEvent(
        client: client,
        loginState: LoginState.loggedOut,
        multipleAccountLoginType: type,
        error: error,
      );

  /// What undoing this session takes, as far as it got.
  Set<_Cleanup> _steps() => {
    _Cleanup.signOut,
    if (_effectsTouched) _Cleanup.restoreEffects,
    if (keepsClient) ...[
      if (_accountAdded) _Cleanup.logoutLast,
    ] else ...[
      _Cleanup.removePush,
      _Cleanup.cancelSubscriptions,
      _host.isStored(id) ? _Cleanup.removeAccount : _Cleanup.discardCandidate,
      _Cleanup.cancelListener,
    ],
  };

  /// Runs the steps that are left, in order. The first one that fails stops the
  /// run and stays for the next [retryCleanup].
  Future<void> _cleanUp() async {
    for (final step in _Cleanup.values) {
      if (!_failedCleanups.contains(step)) continue;
      try {
        await _run(step);
        _failedCleanups.remove(step);
      } catch (e, s) {
        _cleanupError = e;
        _host.report(e, s, 'cleanup $step of $id failed');
        return;
      }
    }
  }

  Future<void> _run(_Cleanup step) => switch (step) {
    _Cleanup.removePush => _bestEffort(
      'push removal',
      () => _host.removePush(id),
    ),
    _Cleanup.cancelSubscriptions => _host.cancelSubscriptions(id),
    _Cleanup.signOut => _bestEffort(
      'sign-out',
      () => _host.signOut(id, quiet: keepsClient),
    ),
    _Cleanup.removeAccount => _host.removeAccount(id),
    _Cleanup.discardCandidate => _host.discardCandidate(id),
    _Cleanup.restoreEffects => _restoreActiveEffects(),
    _Cleanup.cancelListener => _cancelListener(),
    _Cleanup.logoutLast => Future<void>.sync(_host.logoutLast),
  };

  /// The login set the shared state before it was active: the account that is
  /// logged in and active now gets its own back, and with none the state goes
  /// back to "no account".
  Future<void> _restoreActiveEffects() async {
    final active = _host.activeClientName;
    if (active != null && active != id && _host.isLoggedIn(active)) {
      await _host.applyEffects(_host.activeClient);
    } else {
      await _host.clearEffects();
    }
  }

  Future<void> _cancelListener() async {
    final subscription = _loggedInSubscription;
    if (subscription == null) return;
    await subscription.cancel();
    _loggedInSubscription = null;
  }

  /// Cancels the login listener of an account that is active; a failure is
  /// reported and the listener stays for [retryCleanup]. A listener that is
  /// still there only ignores a repeated `loggedIn`.
  Future<void> _cancelListenerReported() =>
      _bestEffort('login listener cancel', _cancelListener);

  void _finishRollback() {
    _cleanupError = null;
    _accountAdded = false;
    _effectsTouched = false;
    if (keepsClient) {
      // Ready for the next try; the quiet-logout marks stay until it logs in,
      // because the SDK can still report a logout after the sign-out.
      _state = LoginSessionState.created;
    } else {
      _state = LoginSessionState.disposed;
      _host.forgetQuiet(id);
      _release();
    }
  }

  void _release() {
    if (_host.pendingCandidateId == _clientId) _host.setPendingCandidate(null);
  }

  String? get _clientId => _client?.clientName;

  /// True when [retryCleanup] has something to run: cleanup steps that
  /// failed, or, for an account that is active, a login listener that is still
  /// there or a set-up that failed.
  bool get needsRetry =>
      _state == LoginSessionState.cleanupFailed ||
      (_state == LoginSessionState.active &&
          (_loggedInSubscription != null || _failedSetUps.isNotEmpty));

  /// Runs again the cleanup steps that failed; for an active account, the
  /// listener cancel and the set-ups that failed. Does nothing otherwise.
  Future<void> retryCleanup() => _enqueue(() async {
    if (_state == LoginSessionState.active) {
      await _cancelListenerReported();
      await _retrySetUps();
      return;
    }
    if (_state != LoginSessionState.cleanupFailed) return;
    _state = LoginSessionState.rollingBack;
    await _cleanUp();
    if (_failedCleanups.isEmpty) {
      _finishRollback();
    } else {
      _state = LoginSessionState.cleanupFailed;
    }
  });

  /// The ToM and federation set-ups write the state of the active account, so
  /// they wait until this one is it. When the account is gone from the app the
  /// set-ups are dropped.
  Future<void> _retrySetUps() async {
    if (!_host.isStored(id)) {
      _failedSetUps.clear();
      return;
    }
    for (final setUp in _failedSetUps.toList()) {
      final writesActive = setUp == _SetUp.tom || setUp == _SetUp.federation;
      if (writesActive && _host.activeClientName != id) continue;
      await _setUp(setUp);
    }
  }

  /// The user left the flow. Waits for a creation and for a login that is
  /// going on, then throws away a candidate that did not become an account.
  /// Calling it again, or twice at once, discards once: the calls run in turn
  /// and the second finds the session already disposed.
  Future<void> dispose() => _enqueue(_dispose);

  Future<void> _dispose() async {
    await _login;
    switch (_state) {
      case LoginSessionState.created:
      case LoginSessionState.loggingIn:
        if (keepsClient) return;
        if (_host.isLoggedIn(id)) return; // the login worked: registering
        _move(LoginSessionState.rollingBack, {
          LoginSessionState.created,
          LoginSessionState.loggingIn,
        });
        _failedCleanups.addAll(_steps());
        await _cleanUp();
        if (_failedCleanups.isEmpty) {
          _finishRollback();
        } else {
          _state = LoginSessionState.cleanupFailed;
          _host.report(
            _cleanupError ?? StateError('cleanup failed'),
            StackTrace.current,
            'cannot dispose $id',
          );
        }
      case LoginSessionState.cleanupFailed:
        _state = LoginSessionState.rollingBack;
        await _cleanUp();
        if (_failedCleanups.isEmpty) {
          _finishRollback();
        } else {
          _state = LoginSessionState.cleanupFailed;
        }
      case LoginSessionState.creating:
      case LoginSessionState.registering:
      case LoginSessionState.rollingBack:
      case LoginSessionState.active:
      case LoginSessionState.disposed:
        return;
    }
  }
}
