import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/account/login_state_watcher.dart';
import 'package:twake_chat/data/account/quiet_logouts.dart';

import '../../fake_client.dart';

class _Database extends MockDatabase {
  @override
  Future<void> delete() async {}
}

/// A homeserver that is fine except that logging out fails.
class _FailingLogoutServer extends http.BaseClient {
  final _fake = FakeMatrixApi();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (!request.url.path.endsWith('/logout')) return _fake.send(request);
    return Future.value(
      http.StreamedResponse(
        Stream.value('{"errcode":"M_UNKNOWN","error":"boom"}'.codeUnits),
        500,
        request: request,
      ),
    );
  }
}

/// `MatrixState` skips a logout it announced to `QuietLogouts`. That only
/// works if `Client.logout()` puts `loggedOut` on the stream the handler
/// listens to, and does so even when the server call fails.
void main() {
  late QuietLogouts quiet;
  late List<LoginState> states;
  late List<bool> skipped;

  setUp(() {
    quiet = QuietLogouts();
    states = [];
    skipped = [];
  });

  void watch(Client client) {
    const LoginStateWatcher().watch(client.onLoginStateChanged.stream, (state) {
      states.add(state);
      skipped.add(quiet.consume(client.clientName, state));
    });
  }

  test('logout() emits loggedOut, which the announced mark skips', () async {
    final client = await getClient(database: _Database());
    watch(client);
    quiet.announce(client.clientName);

    await client.logout();
    await pumpEventQueue();

    expect(states, [LoginState.loggedOut]);
    expect(skipped, [true]);
  });

  test('logout() still emits loggedOut when the server call fails', () async {
    final client = await getClient(
      httpClient: _FailingLogoutServer(),
      database: _Database(),
    );
    watch(client);
    quiet.announce(client.clientName);

    await expectLater(client.logout(), throwsA(anything));
    await pumpEventQueue();

    expect(states, [LoginState.loggedOut]);
    expect(skipped, [true]);
  });

  test('a logout nobody announced is not skipped', () async {
    final client = await getClient(database: _Database());
    watch(client);

    await client.logout();
    await pumpEventQueue();

    expect(skipped, [false]);
  });
}
