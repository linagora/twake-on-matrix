import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/domain/account/entities/account_boot_snapshot.dart';
import 'package:twake_chat/domain/account/entities/account_id.dart';
import 'package:twake_chat/pages/contacts_tab/providers/contacts_providers.dart';
import 'package:twake_chat/providers/account_boot_snapshot_provider.dart';
import 'package:twake_chat/providers/boot_clients_provider.dart';
import 'package:twake_chat/providers/account_repository_provider.dart';
import 'package:twake_chat/providers/accounts_provider.dart';
import 'package:twake_chat/providers/active_user_id_provider.dart';

import '../data/account/fakes.dart';

/// A client the SDK logs in and out in place: same instance, new user id, and
/// no signal to the app.
class _SdkClient extends FakeAccountClient {
  _SdkClient(super.clientName, {String? userId}) : _userId = userId;

  String? _userId;

  @override
  String? get userID => _userId;

  @override
  bool isLogged() => _userId != null;

  void logIn(String userId) => _userId = userId;

  void logOut() => _userId = null;
}

void main() {
  late ProviderContainer container;
  late List<String?> seen;

  void boot(List<_SdkClient> clients) {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        accountClientDataSourceProvider.overrideWithValue(
          FakeAccountClientDataSource(),
        ),
        bootClientsProvider.overrideWithValue(clients),
        bootAccountSnapshotProvider.overrideWithValue(
          const AccountBootSnapshot(),
        ),
      ],
    );
    seen = <String?>[];
    container.listen(
      activeUserIdProvider,
      (_, next) => seen.add(next),
      fireImmediately: true,
    );
  }

  Accounts accounts() => container.read(accountsProvider.notifier);

  test('a placeholder that logs in in place becomes the active user', () async {
    final placeholder = _SdkClient('p');
    boot([placeholder]);
    expect(container.read(currentUserIdProvider), isNull);

    placeholder.logIn('@p:s');
    await accounts().addAccount(const AccountId('p'));
    await container.pump();

    expect(seen, [null, '@p:s']);
    expect(container.read(currentUserIdProvider), '@p:s');
  });

  test(
    'the SDK forgetting the user of the active account is not followed',
    () async {
      final a = _SdkClient('a', userId: '@a:s');
      boot([a, _SdkClient('b', userId: '@b:s')]);

      a.logOut();
      final c = _SdkClient('c', userId: '@c:s');
      container.read(accountClientRegistryProvider).add(c);
      await accounts().addAccount(const AccountId('c'));
      await container.pump();

      expect(seen, ['@a:s']);
      expect(container.read(currentUserIdProvider), '@a:s');
    },
  );
}
