import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/providers/login_sessions.dart';
import 'package:twake_chat/providers/login_sessions_provider.dart';

/// The sessions behind the login screens: logins run at once, and the
/// screens' calls are counted.
class FakeLoginSessions extends Fake implements LoginSessions {
  FakeLoginSessions({Future<Client> Function()? loginClient})
    : _loginClient = loginClient;

  final Future<Client> Function()? _loginClient;
  int discards = 0;

  @override
  Future<Client> loginClient() => _loginClient!();

  @override
  Future<void> discardPending() async => discards++;

  @override
  Future<T> trackLogin<T>(Client client, Future<T> Function() login) => login();
}

/// The slot of the login host, serving [sessions] as they are.
class FakeLoginHostSlot extends LoginHostSlot {
  FakeLoginHostSlot(this._sessions);

  final LoginSessions _sessions;

  @override
  LoginSessions get sessions => _sessions;
}
