import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/model/file_info/file_info.dart';

class DownloadMediaFileFailure extends Failure {
  final dynamic exception;

  const DownloadMediaFileFailure({required this.exception});

  @override
  List<Object?> get props => [exception];
}

class DownloadMediaFileSuccess extends Success {
  const DownloadMediaFileSuccess({required this.fileInfo});

  final FileInfo fileInfo;

  @override
  List<Object?> get props => [fileInfo];
}
