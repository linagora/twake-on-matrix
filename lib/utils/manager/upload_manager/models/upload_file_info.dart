import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/model/file_info/file_info.dart';
import 'package:fluffychat/utils/manager/upload_manager/converters/cancel_token_converter.dart';
import 'package:fluffychat/utils/manager/upload_manager/converters/stream_controller_converter.dart';
import 'package:fluffychat/utils/manager/upload_manager/models/upload_caption_info.dart';
import 'package:fluffychat/utils/manager/upload_manager/models/upload_info.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:matrix/matrix.dart';

part 'upload_file_info.g.dart';

@JsonSerializable(
  converters: [
    StreamControllerConverter(),
    CancelTokenConverter(),
  ],
  explicitToJson: true,
)
class UploadFileInfo extends UploadInfo {
  final StreamController<Either<Failure, Success>> uploadStateStreamController;
  final CancelToken cancelToken;
  final DateTime createdAt;
  final UploadCaptionInfo? captionInfo;
  String? inReplyToEventId;
  bool isFailed;
  FileInfo? fileInfo;
  @JsonKey(includeToJson: false, includeFromJson: false)
  MatrixFile? matrixFile;
  @JsonKey(includeToJson: false, includeFromJson: false)
  MatrixImageFile? thumbnail;
  int? shrinkImageMaxDimension;

  UploadFileInfo({
    required super.txid,
    required this.createdAt,
    required this.uploadStateStreamController,
    required this.cancelToken,
    this.captionInfo,
    this.inReplyToEventId,
    this.isFailed = false,
    this.fileInfo,
    this.matrixFile,
    this.thumbnail,
    this.shrinkImageMaxDimension,
  });

  factory UploadFileInfo.fromJson(Map<String, dynamic> json) =>
      _$UploadFileInfoFromJson(json);

  Map<String, dynamic> toJson() => _$UploadFileInfoToJson(this);

  @override
  List<Object?> get props => [
        txid,
        uploadStateStreamController,
        cancelToken,
        createdAt,
        captionInfo,
        inReplyToEventId,
        isFailed,
        fileInfo,
        matrixFile,
        thumbnail,
        shrinkImageMaxDimension,
      ];
}
