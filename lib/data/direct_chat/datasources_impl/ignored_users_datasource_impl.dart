import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/direct_chat/datasources/ignored_users_datasource.dart';

class IgnoredUsersDatasourceImpl implements IgnoredUsersDatasource {
  const IgnoredUsersDatasourceImpl(this._client);

  final Client? _client;

  @override
  Stream<bool> watchIsIgnored(String userId) async* {
    final client = _client;
    if (client == null) {
      yield false;
      return;
    }
    yield client.ignoredUsers.contains(userId);
    // https://spec.matrix.org/v1.11/client-server-api/#mignored_user_list
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
