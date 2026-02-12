class UploadException implements Exception {
  final dynamic error;

  UploadException({this.error});

  @override
  String toString() => error;
}

class CancelUploadException extends UploadException {
  CancelUploadException() : super(error: 'User cancel upload file');
}
