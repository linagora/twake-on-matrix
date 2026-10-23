import 'package:freezed_annotation/freezed_annotation.dart';

part 'account.freezed.dart';

/// [unavailable]: the account logged out but its removal failed; it stays
/// listed, cannot be switched to, and is removed again until that works.
enum AccountStatus { loggedIn, loggedOut, initFailed, unavailable }

@freezed
abstract class Account with _$Account {
  const Account._();

  const factory Account({
    /// The client name; the only identity an account has in memory.
    required String id,
    required AccountStatus status,

    /// The Matrix user id; null until the account has logged in.
    String? userId,

    /// Set only when [status] is [AccountStatus.initFailed].
    Object? initError,
  }) = _Account;

  bool get isLoggedIn => status == AccountStatus.loggedIn;

  /// The same account with another [status]; an old init error is dropped.
  Account withStatus(AccountStatus status) => Account(
    id: id,
    userId: userId,
    status: status,
    initError: status == AccountStatus.initFailed ? initError : null,
  );
}
