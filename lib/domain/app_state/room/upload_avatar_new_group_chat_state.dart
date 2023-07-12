import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:matrix/matrix.dart';

class UploadAvatarNewGroupChatLoading extends Success {
  @override
  List<Object?> get props => [];
}

class UploadAvatarNewGroupChatSuccess extends Success {
  final Uri uri;

  const UploadAvatarNewGroupChatSuccess({required this.uri});

  @override
  List<Object?> get props => [uri];
}

class UploadAvatarNewGroupChatFailed extends Failure {
  final dynamic exception;

  const UploadAvatarNewGroupChatFailed({required this.exception});

  @override
  List<Object?> get props => [exception];
}

class FileTooBigMatrix extends Failure {
  final FileTooBigMatrixException fileTooBigMatrixException;

  const FileTooBigMatrix(this.fileTooBigMatrixException);

  @override
  List<Object?> get props => [fileTooBigMatrixException];
}