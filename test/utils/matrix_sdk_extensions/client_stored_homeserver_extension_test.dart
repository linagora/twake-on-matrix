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

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    _onRequest(request.url);
    switch (_mode()) {
      case _Mode.healthy:
        return _healthy.send(request);
      case _Mode.unreachable:
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

    http.Client serverThat() =>
        _ModalClient(() => mode, (uri) => requested.add(uri));

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
}
