import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart' show Client;
import 'package:twake_chat/data/account/sources/account_client_registry.dart';
import 'package:twake_chat/data/account/sources/account_client_registry.provider.dart';
import 'package:twake_chat/domain/account/entities/account.dart';
import 'package:twake_chat/domain/account/entities/accounts_state.dart';
import 'package:twake_chat/domain/account/exceptions/account_exception.dart';
import 'package:twake_chat/providers/accounts_provider.dart';
import 'package:twake_chat/providers/matrix_client_provider.dart';

import '../data/account/fakes.dart';

void main() {
  final a = FakeAccountClient('a', userID: '@a:s');
  final b = FakeAccountClient('b', userID: '@b:s');
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

  ProviderContainer containerOn(AccountsState state) => ProviderContainer.test(
    retry: (_, _) => null,
    overrides: [
      accountsProvider.overrideWith(() => _SettableAccounts(state)),
      accountClientRegistryProvider.overrideWithValue(
        AccountClientRegistry()..adoptOnce([a, b]),
      ),
    ],
  );

  final throwsNoActiveClient = throwsA(
    isA<ProviderException>().having(
      (e) => e.exception,
      'exception',
      isA<NoActiveClientException>(),
    ),
  );

  test('matrixClient_whenAnAccountIsActive_returnsItsClient', () {
    // Arrange
    final container = containerOn(
      const Active(accounts: [accountA, accountB], activeId: 'b'),
    );

    // Act
    final client = container.read(matrixClientProvider);

    // Assert
    expect(client, same(b));
  });

  test('matrixClient_duringASwitch_keepsTheClientBeingLeft', () {
    // Arrange
    final container = containerOn(
      const Switching(
        accounts: [accountA, accountB],
        from: 'a',
        to: 'b',
        seq: 1,
      ),
    );

    // Act
    final client = container.read(matrixClientProvider);

    // Assert
    expect(client, same(a));
  });

  test('matrixClient_afterASwitch_followsTheNewActiveAccount', () {
    // Arrange
    final container = containerOn(
      const Active(accounts: [accountA, accountB], activeId: 'a'),
    );
    final seen = <Object>[];
    container.listen(
      matrixClientProvider,
      (_, next) => seen.add(next),
      fireImmediately: true,
    );
    final accounts =
        container.read(accountsProvider.notifier) as _SettableAccounts;

    // Act
    accounts.set(
      const Switching(
        accounts: [accountA, accountB],
        from: 'a',
        to: 'b',
        seq: 1,
      ),
    );
    accounts.set(const Active(accounts: [accountA, accountB], activeId: 'b'));
    // Flushes the pending recomputation to the listener.
    container.read(matrixClientProvider);

    // Assert
    expect(seen, [same(a), same(b)]);
  });

  final noClient = <String, AccountsState>{
    'Booting': const Booting(),
    'NoAccount': const NoAccount(accounts: []),
    'LastLoggedOut': const LastLoggedOut(
      account: Account(id: 'a', status: AccountStatus.loggedOut),
    ),
    'an active account missing from the registry': const Active(
      accounts: [Account(id: 'x', status: AccountStatus.loggedIn)],
      activeId: 'x',
    ),
  };

  for (final MapEntry(key: name, value: state) in noClient.entries) {
    test('matrixClient_whenNoClient_throwsNoActiveClientException ($name)', () {
      // Arrange
      final container = containerOn(state);

      // Act
      Client read() => container.read(matrixClientProvider);

      // Assert
      expect(read, throwsNoActiveClient);
    });
  }
}

class _SettableAccounts extends Accounts {
  _SettableAccounts(this._initial);

  final AccountsState _initial;

  @override
  AccountsState build() => _initial;

  void set(AccountsState next) => state = next;
}
