import 'dart:typed_data';

import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';

class DownloadMediaFileFailure extends Failure {
  final dynamic exception;

  const DownloadMediaFileFailure({required this.exception});

  @override
  List<Object?> get props => [exception];
}

class DownloadMediaFileSuccess extends Success {
  const DownloadMediaFileSuccess({required this.bytes});

  final Uint8List bytes;

  @override
  List<Object?> get props => [bytes];
}
