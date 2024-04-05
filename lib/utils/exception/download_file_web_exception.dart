class DownloadFileWebException implements Exception {
  final dynamic error;

  DownloadFileWebException({
    this.error,
  });

  @override
  String toString() => error;
}
