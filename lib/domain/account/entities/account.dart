import 'package:equatable/equatable.dart';

/// [unavailable]: the account logged out but its removal failed; it stays
/// listed, cannot be switched to, and is removed again until that works.
enum AccountStatus { loggedIn, loggedOut, initFailed, unavailable }

class Account extends Equatable {
  /// The client name; the only identity an account has in memory.
  final String id;

  /// The Matrix user id; null until the account has logged in.
  final String? userId;

  final AccountStatus status;

  /// Set only when [status] is [AccountStatus.initFailed].
  final Object? initError;

  const Account({
    required this.id,
    required this.status,
    this.userId,
    this.initError,
  });

  bool get isLoggedIn => status == AccountStatus.loggedIn;

  /// The same account with another [status]; an old init error is dropped.
  Account withStatus(AccountStatus status) => Account(
    id: id,
    userId: userId,
    status: status,
    initError: status == AccountStatus.initFailed ? initError : null,
  );

  @override
  List<Object?> get props => [id, userId, status, initError];
}
