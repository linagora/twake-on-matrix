import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/account/entities/accounts_state.dart';
import 'package:twake_chat/providers/accounts_provider.dart';

part 'active_user_id_provider.g.dart';

/// The Matrix user id of the active account, read from the `Account` the state
/// holds and not from `Client.userID`: the SDK changes that field in place, on
/// the same instance, with no signal to the app. During a switch it is still
/// the account being left. Null when nobody is logged in (`NoAccount`,
/// `LastLoggedOut`) or the account has no user id yet.
///
/// A `String?`, so consumers keyed on it rebuild only when the user changes.
@Riverpod(keepAlive: true)
String? activeUserId(Ref ref) {
  final state = ref.watch(accountsProvider);
  final id = switch (state) {
    Active(:final activeId) => activeId,
    Switching(:final from) => from,
    _ => null,
  };
  if (id == null) return null;
  return state.accounts
      .where((account) => account.id == id)
      .firstOrNull
      ?.userId;
}
