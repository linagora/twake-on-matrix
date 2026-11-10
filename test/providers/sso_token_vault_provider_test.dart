import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/account/entities/account.dart';
import 'package:twake_chat/domain/account/entities/accounts_state.dart';
import 'package:twake_chat/domain/drive/entities/drive_id_token.dart';
import 'package:twake_chat/providers/accounts_provider.dart';
import 'package:twake_chat/providers/sso_token_vault_provider.dart';
import 'fake_sso_refresh_token_store.dart';

class _FakeAccounts extends Accounts {
  @override
  AccountsState build() => const AccountsState.booting();

  void emit(AccountsState next) => state = next;
}

const _alice = '@alice:example.org';
const _bob = '@bob:example.org';

Account _account(String userId, {AccountStatus? status}) => Account(
  id: 'id-$userId',
  status: status ?? AccountStatus.loggedIn,
  userId: userId,
);

AccountsState _active(List<Account> accounts) =>
    AccountsState.active(accounts: accounts, activeId: accounts.first.id);

DriveIdToken _tokens() => DriveIdToken(
  value: 'id-token',
  expiresAt: DateTime.utc(2030),
  refreshToken: 'refresh-token',
);

void main() {
  late ProviderContainer container;
  late _FakeAccounts accounts;
  late FakeSsoRefreshTokenStore store;

  setUp(() {
    store = FakeSsoRefreshTokenStore();
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        accountsProvider.overrideWith(_FakeAccounts.new),
        useSsoRefreshTokenStore(store),
      ],
    );
    accounts = container.read(accountsProvider.notifier) as _FakeAccounts;
    accounts.emit(_active([_account(_alice), _account(_bob)]));
  });

  group('ssoTokenVaultProvider', () {
    test('forgets the tokens of an account that logs out', () {
      final vault = container.read(ssoTokenVaultProvider)
        ..put(_alice, _tokens())
        ..put(_bob, _tokens());

      accounts.emit(
        _active([
          _account(_bob),
          _account(_alice, status: AccountStatus.loggedOut),
        ]),
      );

      expect(vault.of(_alice), isNull);
      expect(vault.of(_bob), isNotNull);
    });

    test('forgets the refresh token in the secure store of an account that '
        'logs out, and only that one', () async {
      container.read(ssoTokenVaultProvider);
      store.tokens[_alice] = 'a';
      store.tokens[_bob] = 'b';

      accounts.emit(
        _active([
          _account(_bob),
          _account(_alice, status: AccountStatus.loggedOut),
        ]),
      );
      await Future<void>.delayed(Duration.zero);

      expect(store.tokens, {_bob: 'b'});
    });

    test('a secure store that fails does not stop the logout', () async {
      container.read(ssoTokenVaultProvider).put(_alice, _tokens());
      store.failing = true;

      accounts.emit(_active([_account(_bob)]));
      await Future<void>.delayed(Duration.zero);

      expect(container.read(ssoTokenVaultProvider).of(_alice), isNull);
    });

    test('an account that stays logged in keeps its tokens, as after a soft '
        'logout that the SDK recovers', () async {
      final vault = container.read(ssoTokenVaultProvider)
        ..put(_alice, _tokens());
      store.tokens[_alice] = 'a';

      accounts.emit(_active([_account(_alice), _account(_bob)]));
      await Future<void>.delayed(Duration.zero);

      expect(vault.of(_alice), isNotNull);
      expect(store.tokens, {_alice: 'a'});
    });

    test('forgets the tokens of an account that is removed', () {
      final vault = container.read(ssoTokenVaultProvider)
        ..put(_alice, _tokens())
        ..put(_bob, _tokens());

      accounts.emit(_active([_account(_alice)]));

      expect(vault.of(_bob), isNull);
      expect(vault.of(_alice), isNotNull);
    });

    test('forgets the tokens of the last account that logs out', () {
      final vault = container.read(ssoTokenVaultProvider)
        ..put(_alice, _tokens());

      accounts.emit(const AccountsState.noAccount());

      expect(vault.of(_alice), isNull);
    });

    test('keeps the tokens of a login that the accounts do not list yet', () {
      final vault = container.read(ssoTokenVaultProvider)
        ..put('@carol:example.org', _tokens());

      accounts.emit(_active([_account(_alice)]));

      expect(vault.of('@carol:example.org'), isNotNull);
    });

    test('a second login of the same user starts from nothing', () {
      final vault = container.read(ssoTokenVaultProvider)
        ..put(_alice, _tokens());
      accounts.emit(_active([_account(_bob)]));

      accounts.emit(_active([_account(_alice), _account(_bob)]));

      expect(vault.of(_alice), isNull);
    });
  });
}
