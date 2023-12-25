class CheckHomeserverTimeoutException implements Exception {
  final dynamic error;

  CheckHomeserverTimeoutException({
    this.error,
  });

  @override
  String toString() => error;
}
