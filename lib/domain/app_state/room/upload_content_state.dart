import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:matrix/matrix.dart';

class UploadContentLoading extends Success {
  @override
  List<Object?> get props => [];
}

class UploadContentSuccess extends Success {
  final Uri uri;

  const UploadContentSuccess({
    required this.uri,
  });

  @override
  List<Object?> get props => [uri];
}

class UploadContentFailed extends Failure {
  final dynamic exception;

  const UploadContentFailed({required this.exception});

  @override
  List<Object?> get props => [exception];
}

class FileTooBigMatrix extends Failure {
  final FileTooBigMatrixException fileTooBigMatrixException;

  const FileTooBigMatrix(this.fileTooBigMatrixException);

  @override
  List<Object?> get props => [fileTooBigMatrixException];
}
