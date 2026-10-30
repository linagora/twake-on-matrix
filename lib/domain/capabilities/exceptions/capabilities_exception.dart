sealed class CapabilitiesException implements Exception {
  const CapabilitiesException(this.cause);

  final Object cause;

  @override
  String toString() => '$runtimeType: $cause';
}

class GetProfileEditCapabilitiesException extends CapabilitiesException {
  const GetProfileEditCapabilitiesException(super.cause);
}
