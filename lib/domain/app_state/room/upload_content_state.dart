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

class UploadContentFailed extends FeatureFailure {
  const UploadContentFailed(dynamic exception) : super(exception: exception);
}

class FileTooBigMatrix extends FeatureFailure {
  final FileTooBigMatrixException fileTooBigMatrixException;

  const FileTooBigMatrix(this.fileTooBigMatrixException);

  @override
  List<Object?> get props => [fileTooBigMatrixException];
}