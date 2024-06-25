import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:matrix/matrix.dart';

class UploadFileInitial extends Success {
  const UploadFileInitial();

  @override
  List<Object?> get props => [];
}

class ConvertStreamToBytesState extends Success {
  const ConvertStreamToBytesState();

  @override
  List<Object?> get props => [];
}

class GeneratingThumbnailState extends Success {
  const GeneratingThumbnailState();

  @override
  List<Object?> get props => [];
}

class GenerateThumbnailFailed extends Failure {
  const GenerateThumbnailFailed();

  @override
  List<Object?> get props => [];
}

class EncryptingFileState extends Success {
  const EncryptingFileState();

  @override
  List<Object?> get props => [];
}

class EncryptedFileState extends Success {
  const EncryptedFileState();

  @override
  List<Object?> get props => [];
}

class EncryptFailedFileState extends Failure {
  const EncryptFailedFileState();

  @override
  List<Object?> get props => [];
}

class UploadingFileState extends Success {
  final int receive;
  final int total;

  const UploadingFileState({
    required this.receive,
    required this.total,
  });

  @override
  List<Object?> get props => [receive, total];
}

class UploadMatrixFileSuccessState extends Success {
  final MatrixFile file;

  const UploadMatrixFileSuccessState({
    required this.file,
  });

  @override
  List<Object?> get props => [file];
}

class UploadMatrixFileFailedState extends Failure {
  final dynamic exception;

  const UploadMatrixFileFailedState({
    required this.exception,
  });

  @override
  List<Object?> get props => [exception];
}
