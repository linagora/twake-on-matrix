import 'package:equatable/equatable.dart';
import 'package:matrix/matrix.dart';

abstract class DownloadPresentationState with EquatableMixin {
  const DownloadPresentationState();

  @override
  List<Object?> get props => [];
}

class NotDownloadPresentationState extends DownloadPresentationState {
  const NotDownloadPresentationState() : super();
}

class DownloadedPresentationState extends DownloadPresentationState {
  final String filePath;

  const DownloadedPresentationState({required this.filePath}) : super();

  @override
  List<Object?> get props => [filePath];
}

class FileWebDownloadedPresentationState extends DownloadPresentationState {
  final MatrixFile matrixFile;

  const FileWebDownloadedPresentationState({required this.matrixFile})
      : super();

  @override
  List<Object?> get props => [matrixFile];
}

class DownloadingPresentationState extends DownloadPresentationState {
  final int? receive;

  final int? total;

  const DownloadingPresentationState({
    this.receive,
    this.total,
  });

  @override
  List<Object?> get props => [receive, total];
}

class DownloadErrorPresentationState extends DownloadPresentationState {
  final dynamic error;

  const DownloadErrorPresentationState({required this.error});

  @override
  List<Object?> get props => [error];
}
