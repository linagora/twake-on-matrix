import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/utils/manager/upload_manager/models/upload_caption_info.dart';
import 'package:fluffychat/utils/manager/upload_manager/models/upload_info.dart';
import 'package:matrix/matrix.dart';

class UploadFileInfo extends UploadInfo {
  final StreamController<Either<Failure, Success>> uploadStateStreamController;
  final Stream<Either<Failure, Success>> uploadStream;
  final CancelToken cancelToken;
  final DateTime createdAt;
  final UploadCaptionInfo? captionInfo;
  final Event? inReplyTo;

  UploadFileInfo({
    required super.txid,
    required this.createdAt,
    required this.uploadStateStreamController,
    required this.uploadStream,
    required this.cancelToken,
    this.captionInfo,
    this.inReplyTo,
  });

  @override
  List<Object?> get props => [
        txid,
        uploadStateStreamController,
        uploadStream,
        cancelToken,
        createdAt,
        captionInfo,
        inReplyTo,
      ];
}
