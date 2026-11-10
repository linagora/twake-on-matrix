import 'dart:async';

import 'package:twake_chat/data/drive/datasources_impl/sso_refresh_token_store.provider.dart';
import 'package:matrix/matrix.dart' show Logs;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/drive/sources/sso_token_vault.dart';
import 'package:twake_chat/domain/account/entities/accounts_state.dart';
import 'package:twake_chat/providers/accounts_provider.dart';

part 'sso_token_vault_provider.g.dart';

/// One vault for the whole app: the login writes it and the Drive session
/// reads it. An account that logs out takes its tokens with it, whether or not
/// Drive ever used them.
///
/// Leaving the logged-in set is a real logout: the app sets no `onSoftLogout`
/// on its Matrix client, so the SDK refreshes the access token on a soft logout
/// (`Client` of matrix 13.0.0, `onSoftLogout ?? refreshAccessToken`) and only
/// clears the session when that fails
/// (https://spec.matrix.org/v1.19/client-server-api/#soft-logout).
///
/// `main` reads this provider once at startup: it holds the only listener that
/// deletes the stored refresh token of an account that logs out.
@Riverpod(keepAlive: true)
SsoTokenVault ssoTokenVault(Ref ref) {
  final vault = SsoTokenVault();
  Set<String> loggedInUsers(AccountsState state) => {
    for (final account in state.accounts)
      if (account.isLoggedIn && account.userId != null) account.userId!,
  };
  // The refresh token in the secure store leaves with the account too. A
  // store that fails leaves it there: the next login of the user replaces it.
  Future<void> forget(String userId) async {
    try {
      await ref.read(ssoRefreshTokenStoreProvider).delete(userId);
    } on Exception {
      Logs().w('ssoTokenVault: could not delete the stored refresh token');
    }
  }

  ref.listen(accountsProvider, (previous, next) {
    if (previous == null) return;
    final left = loggedInUsers(previous).difference(loggedInUsers(next));
    for (final userId in left) {
      vault.remove(userId);
      unawaited(forget(userId));
    }
  });
  return vault;
}
