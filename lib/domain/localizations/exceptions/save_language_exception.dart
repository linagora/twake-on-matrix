class SaveLanguageException implements Exception {
  const SaveLanguageException(this.cause);

  final Object cause;

  @override
  String toString() => '$runtimeType: $cause';
}
