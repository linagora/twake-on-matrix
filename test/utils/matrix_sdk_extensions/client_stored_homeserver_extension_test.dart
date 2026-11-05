import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/client_stored_homeserver_extension.dart';

import '../../fake_client.dart';

/// Lets the SDK clear the session, which the plain mock database cannot.
class _ClearableDatabase extends MockDatabase {
  @override
  Future<void> clear() async {}
}

enum _Mode { healthy, unreachable, rejectsToken }

/// Delegates to [FakeMatrixApi] while healthy, otherwise fails like the
/// homeserver of the user would.
class _ModalClient extends http.BaseClient {
  _ModalClient(this._mode, this._onRequest);

  final _Mode Function() _mode;
  final void Function(Uri) _onRequest;
  final http.Client _healthy = FakeMatrixApi();

  /// While set, an unreachable request waits for it before failing.
  Completer<void>? holdUnreachable;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    _onRequest(request.url);
    switch (_mode()) {
      case _Mode.healthy:
        return _healthy.send(request);
      case _Mode.unreachable:
        await holdUnreachable?.future;
        throw const SocketException('connection refused');
      case _Mode.rejectsToken:
        return http.StreamedResponse(
          Stream.value(
            utf8.encode(
              '{"errcode":"M_UNKNOWN_TOKEN","error":"Unknown token"}',
            ),
          ),
          401,
          headers: {'content-type': 'application/json'},
        );
    }
  }
}

void main() {
  group('ClientStoredHomeserverExtension::checkStoredHomeserver', () {
    late Client client;
    late _Mode mode;
    late List<Uri> requested;

    late _ModalClient server;

    http.Client serverThat() =>
        server = _ModalClient(() => mode, (uri) => requested.add(uri));

    setUp(() async {
      mode = _Mode.healthy;
      requested = [];
      client = await getClient(
        httpClient: serverThat(),
        database: _ClearableDatabase(),
      );
      requested.clear();
    });

    tearDown(() async {
      await client.dispose(closeDatabase: false);
    });

    test('keeps the stored homeserver and the session when the homeserver '
        'is unreachable', () async {
      final stored = client.homeserver;
      mode = _Mode.unreachable;

      await expectLater(client.checkStoredHomeserver(), throwsA(anything));

      expect(client.homeserver, stored);
      expect(client.isLogged(), isTrue);
      expect(requested.every((uri) => uri.host == stored!.host), isTrue);
    });

    test('does not give the homeserver back to a client cleared while the '
        'check is in flight', () async {
      mode = _Mode.unreachable;
      server.holdUnreachable = Completer<void>();

      final check = expectLater(
        client.checkStoredHomeserver(),
        throwsA(anything),
      );
      await Future<void>.delayed(Duration.zero);
      await client.clear();
      server.holdUnreachable!.complete();
      await check;

      expect(client.isLogged(), isFalse);
      expect(client.homeserver, isNull);
    });

    test('an unreachable account leaves the other account untouched', () async {
      final otherServer = Uri.parse('https://other.example');
      final other = await getClient(database: _ClearableDatabase());
      other.homeserver = otherServer;
      final stored = client.homeserver;
      mode = _Mode.unreachable;

      await expectLater(client.checkStoredHomeserver(), throwsA(anything));

      expect(client.homeserver, stored);
      expect(other.homeserver, otherServer);
      expect(other.isLogged(), isTrue);
      await other.dispose(closeDatabase: false);
    });

    test(
      'the SDK check alone drops the homeserver (why the guard exists)',
      () async {
        mode = _Mode.unreachable;

        await expectLater(
          client.checkHomeserver(client.homeserver!, checkWellKnown: false),
          throwsA(anything),
        );

        expect(client.homeserver, isNull);
      },
    );

    test('throws a StateError when the client holds no homeserver', () async {
      client.homeserver = null;

      await expectLater(client.checkStoredHomeserver(), throwsStateError);
    });

    test('a token rejected by the user\'s own homeserver still ends the '
        'session', () async {
      expect(client.isLogged(), isTrue);
      mode = _Mode.rejectsToken;

      await client.oneShotSync().catchError((_) {});

      expect(client.isLogged(), isFalse);
    });

    test(
      'an unreachable homeserver during sync does not end the session',
      () async {
        mode = _Mode.unreachable;

        await client.oneShotSync().catchError((_) {});

        expect(client.isLogged(), isTrue);
        expect(client.homeserver, isNotNull);
      },
    );
  });

  group('ClientStoredHomeserverExtension::homeserver refresh decisions', () {
    final defaultServer = Uri.parse('https://default.example');
    late Client logged;
    late Client unlogged;

    setUp(() async {
      logged = await getClient(database: _ClearableDatabase());
      unlogged = Client('unlogged', database: _ClearableDatabase());
    });

    tearDown(() async {
      await logged.dispose(closeDatabase: false);
      await unlogged.dispose(closeDatabase: false);
    });

    test('a client with a session never receives the default homeserver', () {
      logged.homeserver = null;

      logged.applyDefaultHomeserverWithoutSession(defaultServer);

      expect(logged.homeserver, isNull);
    });

    test('a client without a session receives the default homeserver', () {
      unlogged.applyDefaultHomeserverWithoutSession(defaultServer);

      expect(unlogged.homeserver, defaultServer);
    });

    test('a client without a session keeps the homeserver it holds', () {
      final held = Uri.parse('https://held.example');
      unlogged.homeserver = held;

      unlogged.applyDefaultHomeserverWithoutSession(defaultServer);

      expect(unlogged.homeserver, held);
    });

    test('reconnect refreshes when the summary is missing', () {
      expect(
        logged.needsHomeserverInformationRefresh(
          hasSummary: false,
          lastCheckFailed: false,
        ),
        isTrue,
      );
    });

    test('reconnect refreshes when the last check failed', () {
      expect(
        logged.needsHomeserverInformationRefresh(
          hasSummary: true,
          lastCheckFailed: true,
        ),
        isTrue,
      );
    });

    test('reconnect refreshes a client that has no homeserver', () {
      unlogged.homeserver = null;

      expect(
        unlogged.needsHomeserverInformationRefresh(
          hasSummary: true,
          lastCheckFailed: false,
        ),
        isTrue,
      );
    });

    test('reconnect does nothing when everything is known and healthy', () {
      expect(
        logged.needsHomeserverInformationRefresh(
          hasSummary: true,
          lastCheckFailed: false,
        ),
        isFalse,
      );
    });
  });

  group('HomeserverCheckLog', () {
    late Client healthy;
    late Client unreachable;
    late HomeserverCheckLog log;

    setUp(() {
      healthy = Client('healthy', database: _ClearableDatabase());
      unreachable = Client('unreachable', database: _ClearableDatabase());
      log = HomeserverCheckLog();
    });

    tearDown(() async {
      await healthy.dispose(closeDatabase: false);
      await unreachable.dispose(closeDatabase: false);
    });

    test('a healthy account does not hide the failure of another one', () {
      log.record(unreachable, failed: true);
      log.record(healthy, failed: false);

      expect(log.hasFailed(unreachable), isTrue);
      expect(log.hasFailed(healthy), isFalse);
    });

    test('a later successful check clears the failure', () {
      log.record(unreachable, failed: true);
      log.record(unreachable, failed: false);

      expect(log.hasFailed(unreachable), isFalse);
    });

    test('an account that was never checked has not failed', () {
      expect(log.hasFailed(healthy), isFalse);
    });
  });
}
