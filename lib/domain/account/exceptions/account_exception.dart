sealed class AccountException implements Exception {
  const AccountException();
}

class UnknownAccountException extends AccountException {
  const UnknownAccountException(this.accountId);

  final String accountId;
}

/// The account is known in memory but its name is not in the store: it is a
/// candidate, not an account yet.
class NotStoredAccountException extends AccountException {
  const NotStoredAccountException(this.accountId);

  final String accountId;
}

/// The name of the account is in the store: it is an account, not a
/// candidate.
class StoredAccountException extends AccountException {
  const StoredAccountException(this.accountId);

  final String accountId;
}

class InvalidAccountTransitionException extends AccountException {
  const InvalidAccountTransitionException({
    required this.transition,
    required this.stateName,
  });

  final String transition;
  final String stateName;
}

/// A switch is running, which refuses a change of the account list. Expected,
/// not a failure: the caller waits for the switch to end and asks again.
class SwitchInProgressException extends AccountException {
  const SwitchInProgressException(this.accountId);

  final String accountId;
}

/// A newer switch replaced this one before it finished.
class SwitchSupersededException extends AccountException {
  const SwitchSupersededException(this.accountId);

  final String accountId;
}
