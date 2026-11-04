sealed class CapabilitiesException implements Exception {
  const CapabilitiesException([this.cause]);

  final Object? cause;

  @override
  String toString() => '$runtimeType: $cause';
}

class NoActiveAccountException extends CapabilitiesException {
  const NoActiveAccountException();
}

class FetchProfileEditCapabilitiesException extends CapabilitiesException {
  const FetchProfileEditCapabilitiesException(Object super.cause);
}
