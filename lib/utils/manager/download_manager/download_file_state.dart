import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:matrix/matrix.dart';

class DownloadFileState extends Success {
  const DownloadFileState();

  @override
  List<Object?> get props => [];
}

class DownloadFileInitial extends Success {
  const DownloadFileInitial();

  @override
  List<Object?> get props => [];
}

class DownloadingFileState extends DownloadFileState {
  final int receive;

  final int total;

  const DownloadingFileState({
    required this.receive,
    required this.total,
  });

  @override
  List<Object?> get props => [receive, total];
}

class DownloadNativeFileSuccessState extends DownloadFileState {
  const DownloadNativeFileSuccessState({
    required this.filePath,
  });

  final String filePath;

  @override
  List<Object?> get props => [filePath];
}

class DownloadMatrixFileSuccessState extends DownloadFileState {
  const DownloadMatrixFileSuccessState({
    required this.matrixFile,
  });

  final MatrixFile matrixFile;

  @override
  List<Object?> get props => [matrixFile];
}

class DecryptingFileState extends DownloadFileState {
  const DecryptingFileState();

  @override
  List<Object?> get props => [];
}

class DownloadFileFailureState extends Failure {
  final dynamic exception;

  const DownloadFileFailureState({
    required this.exception,
  });

  @override
  List<Object?> get props => [exception];
}
