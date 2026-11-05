import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/direct_chat/repositories/ignored_users_repository.dart';

class IgnoredUsersRepositoryImpl implements IgnoredUsersRepository {
  const IgnoredUsersRepositoryImpl(this._client);

  final Client? _client;

  @override
  Stream<bool> watchIsIgnored(String userId) async* {
    final client = _client;
    if (client == null) {
      yield false;
      return;
    }
    yield client.ignoredUsers.contains(userId);
    final ignoredListUpdates = client.onSync.stream.where(
      (update) =>
          update.accountData?.any(
            (data) => data.type == 'm.ignored_user_list',
          ) ??
          false,
    );
    yield* ignoredListUpdates.map((_) => client.ignoredUsers.contains(userId));
  }
}
