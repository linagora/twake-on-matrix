class CheckHomeserverTimeoutException implements Exception {
  final dynamic error;

  CheckHomeserverTimeoutException({
    this.error,
  });

  @override
  String toString() => error;
}

class HomeserverTokenNotFoundException implements Exception {
  final dynamic error;

  HomeserverTokenNotFoundException({
    this.error,
  });

  @override
  String toString() => error;
}
