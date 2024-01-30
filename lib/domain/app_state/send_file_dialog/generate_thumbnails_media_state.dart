import 'package:fluffychat/presentation/state/failure.dart';
import 'package:fluffychat/presentation/state/success.dart';
import 'package:matrix/matrix.dart';

class GenerateThumbnailsMediaState extends UIState {}

class GenerateThumbnailsMediaInitial extends GenerateThumbnailsMediaState {
  final int maxUploadFileSize;

  GenerateThumbnailsMediaInitial({required this.maxUploadFileSize});

  @override
  List<Object?> get props => [maxUploadFileSize];
}

class ConvertReadStreamToBytesSuccess extends GenerateThumbnailsMediaState {
  final MatrixFile oldFile;

  final MatrixFile newFile;

  ConvertReadStreamToBytesSuccess({
    required this.oldFile,
    required this.newFile,
  });

  @override
  List<Object?> get props => [oldFile, newFile];
}

class GenerateThumbnailsMediaSuccess extends GenerateThumbnailsMediaState {
  final MatrixFile file;

  final MatrixImageFile thumbnail;

  GenerateThumbnailsMediaSuccess({required this.file, required this.thumbnail});

  @override
  List<Object?> get props => [file, thumbnail];
}

class GenerateThumbnailsMediaFailure extends FeatureFailure {
  const GenerateThumbnailsMediaFailure(dynamic exception)
      : super(exception: exception);
}
