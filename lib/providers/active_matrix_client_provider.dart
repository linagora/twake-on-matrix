import 'package:matrix/matrix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'active_matrix_client_provider.g.dart';

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
  Client? build() => null;

  void setClient(Client? client) => state = client;
}
