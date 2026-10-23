import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/providers/login_host.dart';
import 'package:twake_chat/providers/login_sessions.dart';

part 'login_sessions_provider.g.dart';

/// Where `MatrixState` hands over the [LoginHost], which needs its client and
/// push state. It is set once, in `initState`, before any login screen exists;
/// a plain holder, so that setting it is not a provider change made while the
/// widget tree builds. It also keeps the [LoginSessions] made for the host, so
/// that they end with it.
class LoginHostSlot {
  LoginHost? _host;
  LoginSessions? _sessions;

  void attach(LoginHost host) {
    _host = host;
    _sessions = null;
  }

  /// The sessions of the unlogged clients that the login screens use.
  LoginSessions get sessions {
    final host = _host ?? (throw StateError('The login host is not set yet'));
    return _sessions ??= LoginSessions(host);
  }

  /// Takes [owner] out when its state goes away, so that the next
  /// `MatrixState` on the container starts with its own host. A host that
  /// someone else has replaced since stays.
  void release(LoginHost owner) {
    if (!identical(_host, owner)) return;
    _host = null;
    _sessions = null;
  }
}

@Riverpod(keepAlive: true)
LoginHostSlot loginHostSlot(Ref ref) => LoginHostSlot();

/// The sessions of the unlogged clients that the login screens use.
@riverpod
LoginSessions loginSessions(Ref ref) =>
    ref.watch(loginHostSlotProvider).sessions;

/// The sessions for the login screens, which are not `ConsumerWidget`s.
extension LoginSessionsOfContext on BuildContext {
  LoginSessions get loginSessions => ProviderScope.containerOf(
    this,
    listen: false,
  ).read(loginSessionsProvider);
}
