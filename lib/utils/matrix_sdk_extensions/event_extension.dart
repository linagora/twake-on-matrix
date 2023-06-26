import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/utils/size_string.dart';
import 'matrix_file_extension.dart';

extension LocalizedBody on Event {
  Future<LoadingDialogResult<MatrixFile?>> getFile(BuildContext context) =>
    showFutureLoadingDialog(
      context: context,
      future: downloadAndDecryptAttachment,
    );

  void saveFile(BuildContext context) async {
    final matrixFile = await getFile(context);

    matrixFile.result?.save(context);
  }

  String get filename {
    return content.tryGet<String>('filename') ?? body;
  }

  String? get fileType {
    return (filename.contains('.')
      ? filename.split('.').last.toUpperCase()
      : content
          .tryGetMap<String, dynamic>('info')
          ?.tryGet<String>('mimetype')
          ?.toUpperCase());
  }

  void shareFile(BuildContext context) async {
    final matrixFile = await getFile(context);

    matrixFile.result?.share(context);
  }

  bool get isAttachmentSmallEnough =>
      infoMap['size'] is int &&
      infoMap['size'] < room.client.database!.maxFileSize;

  bool get isThumbnailSmallEnough =>
      thumbnailInfoMap['size'] is int &&
      thumbnailInfoMap['size'] < room.client.database!.maxFileSize;

  bool get showThumbnail =>
      [MessageTypes.Image, MessageTypes.Sticker, MessageTypes.Video]
          .contains(messageType) &&
      (kIsWeb ||
          isAttachmentSmallEnough ||
          isThumbnailSmallEnough ||
          (content['url'] is String));

  String? get sizeString => content
      .tryGetMap<String, dynamic>('info')
      ?.tryGet<int>('size')
      ?.sizeString;

  Uint8List? _getPlaceHolderMatrixFile(Event event) {
    if (room.sendingFilePlaceholders.isNotEmpty) {
      if (status == EventStatus.synced || status == EventStatus.sent) {
        if (unsigned?.containsKey('transaction_id') == true) {
          final transactionId = unsigned!['transaction_id'];
          return room.sendingFilePlaceholders[transactionId]?.bytes;
        }
      }
    }
    return null;
  }

  Uint8List? getSendingImageData() {
    if (status == EventStatus.sending) {
      return room.sendingFilePlaceholders[eventId]?.bytes;
    } else if (status == EventStatus.synced) {
      return _getPlaceHolderMatrixFile(this);
    } else if (status == EventStatus.sent) {
      return _getPlaceHolderMatrixFile(this); 
    }
    return null;
  }
}
