import 'dart:io';

import 'package:collection/collection.dart';
import 'package:fluffychat/domain/model/extensions/string_extension.dart';
import 'package:fluffychat/utils/clipboard.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/size_string.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

import 'package:matrix/matrix.dart';

import 'matrix_file_extension.dart';

extension LocalizedBody on Event {
  Future<LoadingDialogResult<MatrixFile?>> getFile(
    BuildContext context,
  ) async =>
      TwakeDialog.showFutureLoadingDialogFullScreen(
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

  bool isContains(String? searchTerm) =>
      plaintextBody.toLowerCase().contains(searchTerm?.toLowerCase() ?? '');

  bool get isSearchable =>
      messageType == MessageTypes.Text || messageType == MessageTypes.File;

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

  // Check if the sender of the current event is the same as the compared event.
  bool isSameSenderWith(Event? comparedEvent) {
    // If the compared event is null, it is assumed that the message is the newest.
    if (comparedEvent == null) {
      return true;
    }

    final isPreviousOrNextEventMessage = {
      EventTypes.Message,
      EventTypes.Sticker,
      EventTypes.Encrypted,
      EventTypes.Redaction,
    }.contains(comparedEvent.type);

    // Ignoring events that are not messages, stickers, encrypted or redaction.
    if (!isPreviousOrNextEventMessage) {
      return true;
    }

    return senderId != comparedEvent.senderId;
  }

  bool get isOwnMessage => senderId == room.client.userID;

  bool get timelineOverlayMessage => {
        MessageTypes.Video,
        MessageTypes.Image,
      }.contains(messageType);

  bool get hideDisplayNameInBubbleChat => {
        MessageTypes.Video,
        MessageTypes.Image,
        MessageTypes.File,
      }.contains(messageType);

  bool hideDisplayName(Event? nextEvent) =>
      isOwnMessage ||
      room.isDirectChat ||
      !isSameSenderWith(nextEvent) ||
      type == EventTypes.Encrypted;

  bool get isPinned => room.pinnedEventIds.contains(eventId);

  Future<bool> unpin() async {
    if (!isPinned) {
      return true;
    }
    final pinnedEventIds = room.pinnedEventIds;
    pinnedEventIds.remove(eventId);
    String? message;
    try {
      message = await room.setPinnedEvents(pinnedEventIds);
    } catch (e) {
      Logs().e('$e');
      return false;
    }
    if (message.startsWith('\$')) {
      return true;
    }
    return false;
  }

  Future<void> copy(BuildContext context, Timeline timeline) async {
    if (messageType == MessageTypes.Image && PlatformInfos.isWeb) {
      final matrixFile = getMatrixFile() ??
          await downloadAndDecryptAttachment(
            getThumbnail: true,
          );
      try {
        if (matrixFile.filePath != null) {
          await Clipboard.instance.copyImageAsStream(
            File(matrixFile.filePath!),
            mimeType: mimeType,
          );
        } else if (matrixFile.bytes != null) {
          await Clipboard.instance.copyImageAsBytes(
            matrixFile.bytes!,
            mimeType: mimeType,
          );
        }
      } catch (e) {
        TwakeSnackBar.show(context, L10n.of(context)!.copyImageFailed);
        Logs().e(
          'copySingleEventAction(): failed to copy file ${matrixFile.name}',
        );
      }
    } else {
      copyTextEvent(context, timeline);
    }
  }

  Future<void> copyTextEvent(BuildContext context, Timeline timeline) async {
    await Clipboard.instance
        .copyText(getSelectedEventString(context, timeline));
  }

  String getSelectedEventString(BuildContext context, Timeline timeline) {
    return getDisplayEvent(timeline).calcLocalizedBodyFallback(
      MatrixLocals(L10n.of(context)!),
      hideReply: true,
    );
  }
}
