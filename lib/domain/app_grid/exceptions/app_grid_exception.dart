sealed class AppGridException implements Exception {
  const AppGridException({this.cause});

  final Object? cause;
}

class AppGridConfigurationUnavailableException extends AppGridException {
  const AppGridConfigurationUnavailableException({required Object super.cause});
}
