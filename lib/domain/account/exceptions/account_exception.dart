sealed class AccountException implements Exception {
  const AccountException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class UnknownAccountException extends AccountException {
  const UnknownAccountException(this.accountId)
    : super('No account with this id');

  final String accountId;
}

class InvalidAccountTransitionException extends AccountException {
  const InvalidAccountTransitionException({
    required this.transition,
    required this.stateName,
  }) : super('Transition not allowed from this state');

  final String transition;
  final String stateName;

  @override
  String toString() => '$runtimeType: $transition from $stateName';
}

/// A newer switch replaced this one before it finished.
class SwitchSupersededException extends AccountException {
  const SwitchSupersededException(this.accountId)
    : super('The switch was replaced by a newer one');

  final String accountId;
}
