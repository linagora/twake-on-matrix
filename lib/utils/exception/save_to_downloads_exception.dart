class SaveToDownloadsException implements Exception {
  final dynamic error;

  SaveToDownloadsException({
    this.error,
  });

  @override
  String toString() => error;
}
