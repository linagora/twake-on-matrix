import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:twake_chat/domain/account/entities/account.dart';

part 'accounts_state.freezed.dart';

@freezed
sealed class AccountsState with _$AccountsState {
  const AccountsState._();

  /// Before `initialize`: nothing is known yet.
  const factory AccountsState.booting() = Booting;

  /// Nobody is logged in. [candidateId] is the unlogged placeholder client
  /// that the next login reuses; null when the store held no client at all.
  /// [accounts] are the ones that stay listed anyway: those whose removal is
  /// pending. They are not logged in and the next login does not use them.
  const factory AccountsState.noAccount({
    String? candidateId,
    @Default([]) List<Account> accounts,
  }) = NoAccount;

  const factory AccountsState.active({
    required List<Account> accounts,
    required String activeId,
  }) = Active;

  /// A switch from [from] to [to] is running. The active account is still
  /// [from] until the switch ends. [seq] numbers the switch: whoever settles
  /// it hands the number back, so a stale handler cannot end a newer switch,
  /// even one to the same account.
  const factory AccountsState.switching({
    required List<Account> accounts,
    required String from,
    required String to,
    required int seq,
  }) = Switching;

  /// The last account logged out. It stays so the next login can reuse it.
  const factory AccountsState.lastLoggedOut({required Account account}) =
      LastLoggedOut;

  /// Every account the state knows about, in store order.
  List<Account> get accounts => switch (this) {
    Booting() => const [],
    NoAccount(:final accounts) => accounts,
    Active(:final accounts) => accounts,
    Switching(:final accounts) => accounts,
    LastLoggedOut(:final account) => List.unmodifiable([account]),
  };
}
