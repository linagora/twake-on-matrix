enum SetActiveClientState {
  success,
  unknownClient,

  /// The account is known but cannot be switched to now (it waits for its
  /// removal, or a switch or removal is running).
  unavailable;

  bool get isSuccess => this == SetActiveClientState.success;
}
