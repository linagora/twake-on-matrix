import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';

class UploadFileInitial extends Success {
  const UploadFileInitial();

  @override
  List<Object?> get props => [];
}

class ConvertingStreamToBytesState extends Success {
  const ConvertingStreamToBytesState();

  @override
  List<Object?> get props => [];
}

class ConvertedStreamToBytesState extends Success {
  const ConvertedStreamToBytesState();

  @override
  List<Object?> get props => [];
}

class GeneratingThumbnailState extends Success {
  const GeneratingThumbnailState();

  @override
  List<Object?> get props => [];
}

class GenerateThumbnailSuccess extends Success {
  const GenerateThumbnailSuccess();

  @override
  List<Object?> get props => [];
}

class GenerateThumbnailFailed extends Failure {
  final dynamic exception;
  const GenerateThumbnailFailed({required this.exception});

  @override
  List<Object?> get props => [exception];
}

class EncryptingFileState extends Success {
  final bool isThumbnail;
  const EncryptingFileState({this.isThumbnail = false});

  @override
  List<Object?> get props => [isThumbnail];
}

class EncryptedFileState extends Success {
  final bool isThumbnail;
  const EncryptedFileState({this.isThumbnail = false});

  @override
  List<Object?> get props => [isThumbnail];
}

class EncryptFailedFileState extends Failure {
  final bool isThumbnail;
  final dynamic exception;
  const EncryptFailedFileState({
    required this.exception,
    this.isThumbnail = false,
  });

  @override
  List<Object?> get props => [isThumbnail, exception];
}

class UploadingFileState extends Success {
  final int receive;
  final int total;
  final bool isThumbnail;

  const UploadingFileState({
    required this.receive,
    required this.total,
    this.isThumbnail = false,
  });

  @override
  List<Object?> get props => [receive, total, isThumbnail];
}

class UploadFileSuccessState extends Success {
  final String? eventId;
  final bool isThumbnail;

  const UploadFileSuccessState({this.eventId, this.isThumbnail = false});

  @override
  List<Object?> get props => [eventId, isThumbnail];
}

class UploadFileFailedState extends Failure {
  final dynamic exception;
  final bool isThumbnail;
  final String? txid;

  const UploadFileFailedState({
    required this.exception,
    this.isThumbnail = false,
    this.txid,
  });

  @override
  List<Object?> get props => [exception, isThumbnail, txid];
}
