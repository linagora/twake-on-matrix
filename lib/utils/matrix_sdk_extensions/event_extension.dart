import 'package:fluffychat/domain/model/extensions/string_extension.dart';
import 'package:collection/collection.dart';
import 'package:fluffychat/utils/string_extension.dart';
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

  Future<String?> saveFile(BuildContext context) async {
    final matrixFile = await getFile(context);

    return await matrixFile.result?.downloadFile(context);
  }

  String get filename {
    return (content.tryGet<String>('filename') ?? body).ellipsizeFileName;
  }

  String? get blurHash {
    return infoMap['xyz.amorgan.blurhash'] is String
        ? infoMap['xyz.amorgan.blurhash']
        : null;
  }

  String? get mimeType {
    return content
        .tryGetMap<String, dynamic>('info')
        ?.tryGet<String>('mimetype');
  }

  String? get fileType {
    return (filename.contains('.')
        ? filename.split('.').last.toUpperCase()
        : content
            .tryGetMap<String, dynamic>('info')
            ?.tryGet<String>('mimetype')
            ?.toUpperCase());
  }

  bool get isVideoOrImage =>
      [MessageTypes.Image, MessageTypes.Video].contains(messageType);

  String? get firstValidUrl =>
      messageType == MessageTypes.Text ? text.getFirstValidUrl() : null;

  bool get isContainsLink => firstValidUrl != null;

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

  Duration? get duration {
    return infoMap['duration'] is int
        ? Duration(milliseconds: infoMap['duration'])
        : null;
  }

  String? get sizeString => content
      .tryGetMap<String, dynamic>('info')
      ?.tryGet<int>('size')
      ?.sizeString;

  MatrixFile? getMatrixFile() {
    final txId = unsigned?['transaction_id'] ?? eventId;
    return room.sendingFilePlaceholders[txId];
  }

  Size? getOriginalResolution() {
    if (infoMap['w'] != null && infoMap['h'] != null) {
      return Size(
        double.tryParse(infoMap['w'].toString()) ?? 0,
        double.tryParse(infoMap['h'].toString()) ?? 0,
      );
    }
    return null;
  }

  User? getUser() {
    return room
        .getParticipants()
        .firstWhereOrNull((user) => user.id == senderId);
  }
}
