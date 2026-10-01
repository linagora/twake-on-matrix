import 'package:matrix/matrix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'active_matrix_client_provider.g.dart';

/// Immutable snapshot of the active client, captured at push time.
///
/// A new instance is emitted on every `setClient` call: the Matrix SDK mutates
/// `Client.userID` in place at login, so identity-based change detection would
/// never notify consumers when the same instance becomes logged in.
class ActiveClientSnapshot {
  const ActiveClientSnapshot(this.client);

  final Client? client;

  /// Matrix ID of the active account, `null` before login.
  String? get userId => client?.userID;
}

/// Transitional bridge for the Riverpod migration (Phase 0).
///
/// The Matrix [Client] is still created and owned by `ClientManager` /
/// `MatrixState`. Instead of duplicating the instance (which would start a
/// second sync loop), `MatrixState` pushes the active client here, and Riverpod
/// consumers read it through this provider.
///
/// Once Phase 0 moves client creation into Riverpod, this notifier is replaced
/// by a plain `@Riverpod(keepAlive: true) Client` provider and the
/// `Matrix.of(context)` call sites migrate.
@Riverpod(keepAlive: true)
class ActiveMatrixClient extends _$ActiveMatrixClient {
  @override
  ActiveClientSnapshot build() => const ActiveClientSnapshot(null);

  void setClient(Client? client) => state = ActiveClientSnapshot(client);
}
