sealed class AccountException implements Exception {
  const AccountException();
}

class UnknownAccountException extends AccountException {
  const UnknownAccountException(this.accountId);

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

/// A newer switch replaced this one before it finished.
class SwitchSupersededException extends AccountException {
  const SwitchSupersededException(this.accountId);

  final String accountId;
}
