class DownloadingException implements Exception {
  final dynamic error;

  DownloadingException({
    this.error,
  });

  @override
  String toString() => error;
}

class CancelDownloadingException extends DownloadingException {
  CancelDownloadingException()
      : super(
          error: 'User cancel downloading file',
        );
}
