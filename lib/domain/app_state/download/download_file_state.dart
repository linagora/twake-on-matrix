import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';

class DownloadMediaFileFailure extends Failure {
  final dynamic exception;

  const DownloadMediaFileFailure({required this.exception});

  @override
  List<Object?> get props => [exception];
}

class DownloadMediaFileSuccess extends Success {
  const DownloadMediaFileSuccess({required this.filePath});

  final String filePath;

  @override
  List<Object?> get props => [filePath];
}
