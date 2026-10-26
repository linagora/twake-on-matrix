import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matrix/matrix.dart' show Client;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/domain/account/entities/account_boot_snapshot.dart';
import 'package:twake_chat/data/account/sources/account_client_registry.dart';
import 'package:twake_chat/domain/account/entities/account.dart';
import 'package:twake_chat/domain/account/entities/account_id.dart';
import 'package:twake_chat/domain/account/entities/accounts_state.dart';
import 'package:twake_chat/pages/contacts_tab/providers/contacts_providers.dart';
import 'package:twake_chat/providers/account_boot_snapshot_provider.dart';
import 'package:twake_chat/providers/boot_clients_provider.dart';
import 'package:twake_chat/providers/account_repository_provider.dart';
import 'package:twake_chat/providers/accounts_provider.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
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

  group('by state', () {
    final a = _SdkClient('a', userId: '@a:s');
    final b = _SdkClient('b', userId: '@b:s');
    const accountA = Account(
      id: 'a',
      userId: '@a:s',
      status: AccountStatus.loggedIn,
    );
    const accountB = Account(
      id: 'b',
      userId: '@b:s',
      status: AccountStatus.loggedIn,
    );
    const waiting = Account(id: 'w', status: AccountStatus.unavailable);
    const withoutUser = Account(id: 'a', status: AccountStatus.loggedIn);

    final table = <String, (AccountsState, Client?, String?)>{
      'Booting': (const Booting(), null, null),
      'NoAccount': (const NoAccount(accounts: [waiting]), null, null),
      'Active': (
        const Active(accounts: [accountA, accountB], activeId: 'b'),
        b,
        '@b:s',
      ),
      'Switching keeps the account that is left': (
        const Switching(
          accounts: [accountA, accountB],
          from: 'a',
          to: 'b',
          seq: 1,
        ),
        a,
        '@a:s',
      ),
      'LastLoggedOut': (
        const LastLoggedOut(
          account: Account(id: 'a', status: AccountStatus.loggedOut),
        ),
        null,
        null,
      ),
      'an active account without a user id': (
        const Active(accounts: [withoutUser], activeId: 'a'),
        a,
        null,
      ),
    };

    for (final entry in table.entries) {
      test('${entry.key}: active client and user id', () {
        final (state, client, userId) = entry.value;
        final registry = AccountClientRegistry()..replaceAll([a, b]);
        final fixed = ProviderContainer.test(
          overrides: [
            accountsProvider.overrideWith(() => _FixedAccounts(state)),
            accountClientRegistryProvider.overrideWithValue(registry),
          ],
        );

        expect(fixed.read(activeMatrixClientProvider), client);
        expect(fixed.read(activeUserIdProvider), userId);
      });
    }
  });
}

/// An `Accounts` notifier that starts on a given state.
class _FixedAccounts extends Accounts {
  _FixedAccounts(this._state);

  final AccountsState _state;

  @override
  AccountsState build() => _state;
}
