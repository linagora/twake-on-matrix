import 'package:matrix/matrix.dart' show Client;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/account/exceptions/account_exception.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

part 'matrix_client_provider.g.dart';

/// The active account's `Client`, for screens behind login. Fails with
/// [NoActiveClientException], wrapped in a `ProviderException` on read, when
/// `activeMatrixClientProvider` is null.
@Riverpod(keepAlive: true)
Client matrixClient(Ref ref) {
  final client = ref.watch(activeMatrixClientProvider);
  if (client == null) throw const NoActiveClientException();
  return client;
}
