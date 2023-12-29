enum SetActiveClientState {
  success,
  unknownClient;

  bool get isSuccess => this == SetActiveClientState.success;
}
