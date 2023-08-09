import 'package:fluffychat/app_state/failure.dart';

class DownloadFileForPreviewFailure extends Failure {
  final dynamic exception;

  const DownloadFileForPreviewFailure({required this.exception});

  @override
  List<Object?> get props => [exception];
}
