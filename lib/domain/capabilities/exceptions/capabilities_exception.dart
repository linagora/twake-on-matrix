sealed class CapabilitiesException implements Exception {
  const CapabilitiesException(this.cause);

  final Object cause;

  @override
  String toString() => '$runtimeType: $cause';
}

class FetchProfileEditCapabilitiesException extends CapabilitiesException {
  const FetchProfileEditCapabilitiesException(super.cause);
}
