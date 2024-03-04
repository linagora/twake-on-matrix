import 'package:fluffychat/app_state/failure.dart';

class DownloadFileFailed extends Failure {
  final dynamic exception;

  const DownloadFileFailed({required this.exception});

  @override
  List<Object?> get props => [exception];
}
