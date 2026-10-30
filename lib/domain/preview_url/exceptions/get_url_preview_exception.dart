class GetUrlPreviewException implements Exception {
  const GetUrlPreviewException(this.cause);

  final Object cause;

  @override
  String toString() => '$runtimeType: $cause';
}
