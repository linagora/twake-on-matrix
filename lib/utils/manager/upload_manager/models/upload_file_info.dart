import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/utils/manager/upload_manager/models/upload_info.dart';

class UploadFileInfo extends UploadInfo {
  final StreamController<Either<Failure, Success>> uploadStateStreamController;
  final Stream<Either<Failure, Success>> uploadStream;
  final CancelToken cancelToken;
  final DateTime createdAt;

  UploadFileInfo({
    required super.txid,
    required this.createdAt,
    required this.uploadStateStreamController,
    required this.uploadStream,
    required this.cancelToken,
  });

  @override
  List<Object?> get props => [
        txid,
        uploadStateStreamController,
        uploadStream,
        cancelToken,
      ];
}
