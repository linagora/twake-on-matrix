enum SetActiveClientState {
  success,
  unknownClient,

  /// The account is known but cannot be switched to now (it waits for its
  /// removal, or a removal is running).
  unavailable,

  /// A newer request for another account replaced this one. The account is
  /// untouched and still usable: it only lost the race to be the active one.
  superseded;

  bool get isSuccess => this == SetActiveClientState.success;
}
