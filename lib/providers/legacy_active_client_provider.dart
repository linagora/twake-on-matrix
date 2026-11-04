import 'package:matrix/matrix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'legacy_active_client_provider.g.dart';

// TODO: [transitional] TW-3302 - drop this file once `MatrixState` boots
// through the account providers (TW-3302 5/5): `accountsProvider` then drives
// the active client and the `setClient` pushes go away.

/// Whether `accountsProvider` drives `activeMatrixClientProvider` and
/// `activeUserIdProvider`. False until the boot overrides are wired in
/// `main.dart`: nothing writes `accountsProvider` before that, so both read the
/// client `MatrixState` pushes into [LegacyActiveClient].
@Riverpod(keepAlive: true)
bool accountsDriveActiveClient(Ref ref) => false;

/// Snapshot of the client `MatrixState` pushes, captured at push time: the SDK
/// sets `Client.userID` in place at login, so each push is a new value.
class LegacyActiveClientSnapshot {
  const LegacyActiveClientSnapshot(this.client);

  final Client? client;

  String? get userId => client?.userID;
}

/// The active client `MatrixState` pushes while it still owns the clients.
@Riverpod(keepAlive: true)
class LegacyActiveClient extends _$LegacyActiveClient {
  @override
  LegacyActiveClientSnapshot build() => const LegacyActiveClientSnapshot(null);

  void setClient(Client? client) => state = LegacyActiveClientSnapshot(client);
}
