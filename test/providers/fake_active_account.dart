import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:matrix/matrix.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/providers/active_user_id_provider.dart';

/// Overrides the two providers that tell which account is active, for a test
/// that keeps one client. The user id is read from [client] when first needed,
/// so a test can stub `userID` after it built its container.
List<Override> activeAccountOverrides(Client? client) => [
  activeMatrixClientProvider.overrideWithValue(client),
  activeUserIdProvider.overrideWith((ref) => client?.userID),
];

/// The active client of a test that changes it: with
/// [activeAccountOverridesFollowing] both providers follow it, like a switch of
/// account.
class FakeActiveAccount extends Notifier<Client?> {
  @override
  Client? build() => null;

  void set(Client? client) => state = client;
}

final fakeActiveAccountProvider = NotifierProvider<FakeActiveAccount, Client?>(
  FakeActiveAccount.new,
);

List<Override> activeAccountOverridesFollowing() => [
  activeMatrixClientProvider.overrideWith(
    (ref) => ref.watch(fakeActiveAccountProvider),
  ),
  activeUserIdProvider.overrideWith(
    (ref) => ref.watch(fakeActiveAccountProvider)?.userID,
  ),
];
