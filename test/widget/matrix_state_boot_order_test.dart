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
import 'package:twake_chat/domain/contact/sources/phonebook_resolver.dart';
import 'package:twake_chat/pages/contacts_tab/providers/contacts_providers.dart';
import 'package:twake_chat/utils/network_connection_service.dart';
import 'package:twake_chat/domain/account/entities/account_boot_snapshot.dart';
import 'package:twake_chat/providers/account_boot_snapshot_provider.dart';
import 'package:twake_chat/providers/account_repository_provider.dart';
import 'package:twake_chat/providers/boot_clients_provider.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:twake_chat/widgets/set_active_client_state.dart';

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

/// `setActiveClient` stops the contacts lookup of the account being left.
class _NoopPhonebookResolver extends Fake implements PhonebookResolver {
  @override
  Future<void> cancel() async {}
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

  testWidgets('MatrixState starts on the boot accounts that main overrode', (
    tester,
  ) async {
    final client = _BootClient('a', userID: '@a:s');
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        accountClientDataSourceProvider.overrideWithValue(
          FakeAccountClientDataSource(),
        ),
        bootClientsProvider.overrideWithValue([client]),
        bootAccountSnapshotProvider.overrideWithValue(
          const AccountBootSnapshot(),
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

    // The state adopts the boot clients at its first read, whichever
    // provider is read first.
    expect(active, same(client));
    expect(listed, [client]);
  });

  testWidgets('setActiveClient tells an account that waits for its removal '
      'from an unknown one', (tester) async {
    final active = _BootClient('a', userID: '@a:s');
    final waiting = _BootClient('b', userID: '@b:s');
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        accountClientDataSourceProvider.overrideWithValue(
          FakeAccountClientDataSource(),
        ),
        bootClientsProvider.overrideWithValue([active, waiting]),
        bootAccountSnapshotProvider.overrideWithValue(
          const AccountBootSnapshot(pendingRemovalIds: {'b'}),
        ),
        phonebookResolverProvider.overrideWithValue(_NoopPhonebookResolver()),
      ],
    );
    addTearDown(container.dispose);

    SetActiveClientState? known;
    SetActiveClientState? unknown;
    await runZonedGuarded(() async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Matrix(clients: [active, waiting], child: const SizedBox()),
          ),
        ),
      );
      final matrix = tester.state<MatrixState>(find.byType(Matrix));
      known = await tester.runAsync(() => matrix.setActiveClient(waiting));
      unknown = await tester.runAsync(
        () => matrix.setActiveClient(_BootClient('x', userID: '@x:s')),
      );
    }, (_, _) {});

    expect(known, SetActiveClientState.unavailable);
    expect(unknown, SetActiveClientState.unknownClient);
  });
}
