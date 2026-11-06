import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/account/login_sessions.dart';
import 'package:twake_chat/data/account/login_host.dart';
import 'package:twake_chat/domain/model/homeserver_summary.dart';

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
  HomeserverSummary? homeserverSummary;

  @override
  Future<HomeserverSummary> checkHomeserver(
    Client client,
    Uri homeserver, {
    Duration? timeout,
  }) async {
    final (discovery, versions, loginFlows, _) = await client.checkHomeserver(
      homeserver,
    );
    return homeserverSummary = HomeserverSummary(
      discoveryInformation: discovery,
      versions: versions,
      loginFlows: loginFlows,
    );
  }

  @override
  Future<void> discardPending() async {
    homeserverSummary = null;
    discards++;
  }

  /// A `MatrixState` mounted with these sessions attaches its host to them.
  @override
  void attach(LoginHost host) {}

  @override
  void release(LoginHost owner) {}

  @override
  Future<T> trackLogin<T>(Client client, Future<T> Function() login) => login();
}
