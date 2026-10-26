import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/account/repositories/account_repository_impl.dart';
import 'package:twake_chat/data/account/repositories/client_account_boot_port.dart';
import 'package:twake_chat/data/account/sources/account_client_registry.dart';
import 'package:twake_chat/data/account/sources/pending_removals_source.dart';
import 'package:twake_chat/data/account/sources/persisted_active_account_source.dart';
import 'package:twake_chat/domain/account/entities/account.dart';
import 'package:twake_chat/utils/famedlysdk_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  late AccountClientRegistry registry;
  late AccountRepositoryImpl repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    registry = AccountClientRegistry();
    repository = AccountRepositoryImpl(
      dataSource: FakeAccountClientDataSource(),
      persistedActiveAccount: PersistedActiveAccountSource(Store()),
      pendingRemovals: PendingRemovalsSource(Store()),
      pendingPushRemovals: PendingRemovalsSource(Store()),
      pendingCandidateDiscards: PendingRemovalsSource(Store()),
      registry: registry,
    );
  });

  group('ClientAccountBootPort', () {
    test('adopts the boot clients into the repository', () {
      final a = FakeAccountClient('a', userID: '@a:s');
      final port = ClientAccountBootPort(repository: repository, clients: [a]);

      expect(port.adopt(pendingRemovals: const {}), const [
        Account(id: 'a', userId: '@a:s', status: AccountStatus.loggedIn),
      ]);
      expect(registry['a'], same(a));
    });
  });
}
