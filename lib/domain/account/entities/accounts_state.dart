import 'package:equatable/equatable.dart';
import 'package:twake_chat/domain/account/entities/account.dart';

sealed class AccountsState extends Equatable {
  const AccountsState();

  /// Every account the state knows about, in store order.
  List<Account> get accounts;

  @override
  List<Object?> get props => [accounts];
}

/// Before `initialize`: nothing is known yet.
final class Booting extends AccountsState {
  const Booting();

  @override
  List<Account> get accounts => const [];
}

/// Nobody is logged in. [candidateId] is the unlogged placeholder client
/// that the next login reuses; null when the store held no client at all.
/// [accounts] are the ones that stay listed anyway: those whose removal is
/// pending. They are not logged in and the next login does not use them.
final class NoAccount extends AccountsState {
  final String? candidateId;

  @override
  final List<Account> accounts;

  const NoAccount({this.candidateId, this.accounts = const []});

  @override
  List<Object?> get props => [candidateId, accounts];
}

final class Active extends AccountsState {
  @override
  final List<Account> accounts;
  final String activeId;

  Active({required List<Account> accounts, required this.activeId})
    : accounts = List.unmodifiable(accounts);

  @override
  List<Object?> get props => [accounts, activeId];
}

/// A switch from [from] to [to] is running. The active account is still
/// [from] until the switch ends. [seq] numbers the switch: whoever settles it
/// hands the number back, so a stale handler cannot end a newer switch, even
/// one to the same account.
final class Switching extends AccountsState {
  @override
  final List<Account> accounts;
  final String from;
  final String to;
  final int seq;

  Switching({
    required List<Account> accounts,
    required this.from,
    required this.to,
    this.seq = 0,
  }) : accounts = List.unmodifiable(accounts);

  @override
  List<Object?> get props => [accounts, from, to, seq];
}

/// The last account logged out. It stays so the next login can reuse it.
final class LastLoggedOut extends AccountsState {
  final Account account;

  const LastLoggedOut({required this.account});

  @override
  List<Account> get accounts => List.unmodifiable([account]);

  @override
  List<Object?> get props => [account];
}

/// Every account that is not waiting for its removal failed to initialise and
/// none is logged in. [id] and [error] are those of the first failed one;
/// [accounts] are the ones that stay listed, those whose removal is pending.
final class AccountInitFailed extends AccountsState {
  final String id;
  final Object? error;

  @override
  final List<Account> accounts;

  const AccountInitFailed({
    required this.id,
    this.error,
    this.accounts = const [],
  });

  @override
  List<Object?> get props => [id, error, accounts];
}
