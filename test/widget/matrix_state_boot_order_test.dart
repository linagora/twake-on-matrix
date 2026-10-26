import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:matrix/encryption.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/utils/network_connection_service.dart';
import 'package:twake_chat/providers/account_repository_provider.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/widgets/matrix.dart';

import '../data/account/fakes.dart';

/// A client with the streams and the http client `MatrixState` opens at boot.
class _BootClient extends FakeAccountClient {
  _BootClient(super.clientName, {super.userID});

  final _onRoomKeyRequest = CachedStreamController<RoomKeyRequest>();
  final _onKeyVerificationRequest = CachedStreamController<KeyVerification>();
  final _onLoginStateChanged = CachedStreamController<LoginState>();
  final _onUiaRequest = CachedStreamController<UiaRequest>();
  final _onSyncStatus = CachedStreamController<SyncStatusUpdate>();
  final _onToDeviceEvent = CachedStreamController<ToDeviceEvent>();
  final _httpClient = http.Client();

  @override
  CachedStreamController<RoomKeyRequest> get onRoomKeyRequest =>
      _onRoomKeyRequest;

  @override
  CachedStreamController<KeyVerification> get onKeyVerificationRequest =>
      _onKeyVerificationRequest;

  @override
  CachedStreamController<LoginState> get onLoginStateChanged =>
      _onLoginStateChanged;

  @override
  CachedStreamController<UiaRequest> get onUiaRequest => _onUiaRequest;

  @override
  CachedStreamController<SyncStatusUpdate> get onSyncStatus => _onSyncStatus;

  @override
  CachedStreamController<ToDeviceEvent> get onToDeviceEvent => _onToDeviceEvent;

  @override
  http.Client get httpClient => _httpClient;
}

class _FakeNetworkConnectionService extends Fake
    implements NetworkConnectionService {
  @override
  Stream<ConnectivityResult> getStreamInstance() => const Stream.empty();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    getIt.registerSingleton<NetworkConnectionService>(
      _FakeNetworkConnectionService(),
    );
  });
  tearDown(getIt.reset);

  testWidgets(
    'MatrixState adopts the boot accounts before it listens to the account providers',
    (tester) async {
      final client = _BootClient('a', userID: '@a:s');
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          accountClientDataSourceProvider.overrideWithValue(
            FakeAccountClientDataSource(),
          ),
        ],
      );
      addTearDown(container.dispose);

      Client? active;
      List<Client>? listed;
      // The post-frame `initMatrix` needs the whole app wiring, which this test
      // does not cover: its failures are dropped, `initState` is what is read.
      await runZonedGuarded(() async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Matrix(clients: [client], child: const SizedBox()),
            ),
          ),
        );
        active = container.read(activeMatrixClientProvider);
        listed = container.read(accountClientsProvider);
      }, (_, _) {});

      // Listening first would build the providers on an empty registry and
      // leave them without the active client.
      expect(active, same(client));
      expect(listed, [client]);
    },
  );
}
